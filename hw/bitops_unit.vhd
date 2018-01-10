library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity bitops_unit is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        --decode/issue
        new_request_dec : in std_logic;
        new_request : in std_logic;
        ready : out std_logic;
        
        --writeback
        early_done : out std_logic;
        accepted : in std_logic;
        rd : out std_logic_vector(31 downto 0);
        
        --inputs
        rs1 : in std_logic_vector(31 downto 0);
        fn3 : in std_logic_vector(2 downto 0);
        fn3_dec : in std_logic_vector(2 downto 0)
    );
end bitops_unit;
    
architecture Behavioral of bitops_unit is
TYPE statecode IS (rdy, hold, bitoperations, done);
SIGNAL PS, NS : statecode;
CONSTANT zero5: std_logic_vector(4 downto 0) := "00000";
   
begin
registers:PROCESS(clk, rst)
BEGIN
	IF(rst = '1') THEN
		PS <= rdy;
	ELSIF(RISING_EDGE(clk)) THEN
		PS <= NS;
	END IF;
END PROCESS;


IFL:PROCESS(accepted, new_request_dec, PS)
BEGIN
CASE PS IS
	WHEN rdy =>
		IF(new_request_dec = '0') THEN
			NS <= rdy;
		ELSE
			NS <= hold;
		END IF;
	WHEN hold =>
		NS <= bitoperations;	
	WHEN bitoperations =>
		NS <= done;
	WHEN done =>
		IF(accepted = '0') THEN
			NS <= done;
		ELSE
			NS <= rdy;
		END IF;	
	END CASE;
END PROCESS;

OFL:PROCESS(PS, rs1,fn3)
Variable temp_out : unsigned (5 downto 0) := (OTHERS => '0');
Variable temp_CLZ : std_logic_vector(31 downto 0);
Variable CLZ_done : std_logic;
BEGIN
CASE PS IS
	WHEN rdy =>
		ready <= '1';
		early_done <= '0';
	WHEN hold =>
		ready <= '0';
	WHEN bitoperations =>
		early_done <= '1';
		CASE fn3 IS
			WHEN "000" => --CLZ
				temp_CLZ := rs1;
				CLZ_done := '0';
				for i in 0 to 32 loop
					if (CLZ_done = '0') then 
						if(temp_CLZ(31) = '0') then
							temp_CLZ := temp_CLZ(30 downto 0) & '1';
						else
							CLZ_done := '1';
							rd <= STD_LOGIC_VECTOR(to_unsigned(i,32));
						end if;				
					end if;
				end loop;	
			WHEN "001" => --POPC
				temp_out := (OTHERS => '0');
				for i in 0 TO 31 loop
					temp_out := temp_out + unsigned(zero5 & std_logic(rs1(i)));
				end loop;
				rd(31 downto 6) <= (Others => '0'); 
				rd(5 downto 0) <= std_logic_vector(temp_out);
			WHEN "010" => --SWAPB
				rd <= rs1(7 downto 0) & rs1(15 downto 8) & rs1(23 downto 16) & rs1 (31 downto 24);
			WHEN OTHERS =>
				rd <= (Others => '1');
		END CASE;
	WHEN done =>	
END CASE;
END PROCESS;


end Behavioral;

