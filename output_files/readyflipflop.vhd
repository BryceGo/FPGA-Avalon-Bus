library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY readyflipflop IS
PORT(	clock, enable,rst	: IN STD_LOGIC;
		D		: IN STD_LOGIC;
		Q		: OUT STD_LOGIC;
		);
END flipflop;



ARCHITECTURE behaviour OF readyflipflop IS
BEGIN
	ff:PROCESS(clock,rst)
	BEGIN
		IF(rst = '1') THEN
			Q <= (OTHERS => '0');
		ELSIF(RISING_EDGE(clock)) THEN
			IF(enable = '1') THEN
				Q <= D;
			END IF;		
		END IF;
	END PROCESS;
END ARCHITECTURE;