

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity avalon_master is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        --Bus ports
        addr : out std_logic_vector(31 downto 0);
        avread : out std_logic;
        avwrite : out std_logic;
        byteenable : out std_logic_vector(3 downto 0);
        readdata : in std_logic_vector(31 downto 0);
        writedata : out std_logic_vector(31 downto 0);
        waitrequest : in std_logic;
        readdatavalid : in std_logic;
        writeresponsevalid : in std_logic;
        
        --L/S interface
        addr_in : in std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        data_valid : out std_logic;
        ready : out std_logic;
        new_request : in std_logic;
        rnw : in std_logic;
        be : in std_logic_vector(3 downto 0);
        data_ack : in std_logic
    );
end avalon_master;
    
architecture Behavioral of avalon_master is

COMPONENT flipflop IS
GENERIC(N : INTEGER := 4);
PORT(	clock, enable,rst	: IN STD_LOGIC;
		D		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		Q		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
		);
END COMPONENT;

COMPONENT readyflipflop IS
PORT(	clock, enable,rst	: IN STD_LOGIC;
		D		: IN STD_LOGIC;
		Q		: OUT STD_LOGIC
		);
END COMPONENT;

TYPE statecode IS (rdy,datain,dataout, dataack);
SIGNAL PS, NS	: statecode;

SIGNAL addrd				: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL byteenabled		: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL avrnwd				: STD_LOGIC;
SIGNAL writedatad			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL data_outd			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL datavalidd			: STD_LOGIC;

begin


	registers:PROCESS(clk,rst)	
	BEGIN
		IF(RISING_EDGE(clk)) THEN
			IF(rst = '1') THEN
				PS <= rdy;
			ELSE
				PS <= NS;
			END IF;
		END IF;
	END PROCESS;
	
	IFL:PROCESS(PS, new_request,waitrequest,readdatavalid,data_ack)
	BEGIN
		CASE PS IS
			WHEN rdy =>
				IF(new_request = '1') THEN
					NS <= datain;
				ELSE
					NS <= rdy;
				END IF;
			
			WHEN datain =>
				IF(waitrequest = '0') THEN
					IF(avrnwd = '1') THEN
						NS <= dataout;
					ELSE
						NS <= rdy;
					END IF;
				ELSE
					NS <= datain;
				END IF;
			
			WHEN dataout =>
				IF(waitrequest = '0') THEN
					NS <= dataout;
				ELSE
					NS <= dataack;
				END IF;
			WHEN dataack =>
				IF(data_ack = '1') THEN
					NS <= rdy;
				ELSE
					NS <= dataack;
				END IF;
		END CASE;
	END PROCESS;
	
	OFL:PROCESS(PS, addrd,writedatad, byteenabled,avrnwd)
	BEGIN
		CASE PS IS
			WHEN rdy =>
				ready <= '1';
				avread <= '0';
				avwrite <= '0';
				data_valid <= '0';
			WHEN datain =>
				ready <= '0';
				avread <= avrnwd;
				avwrite <= NOT(avrnwd);				
			WHEN dataout =>
				avread <= '0';
				avwrite <= '0';
			WHEN dataack =>
				data_valid <= '1';
		END CASE;
	END PROCESS;

	address_in0: flipflop GENERIC MAP(32) PORT MAP(rst => rst, clock => clk, enable => new_request,D => addr_in, Q => addr);
	data_in0: flipflop GENERIC MAP(32) PORT MAP(rst => rst, clock => clk, enable => new_request,D => data_in, Q => writedata);
	rnw0: flipflop GENERIC MAP(1) PORT MAP(rst => rst, clock => clk, enable => new_request,D(0) => rnw, Q(0) => avrnwd);
	be0: flipflop GENERIC MAP(4) PORT MAP(rst => rst, clock => clk, enable => new_request,D => be, Q => byteenable);
	
	data_out0: flipflop GENERIC MAP(32) PORT MAP(rst => rst, clock => clk, enable => NOT(waitrequest), D => readdata, Q => data_out);
	


	
end Behavioral;
