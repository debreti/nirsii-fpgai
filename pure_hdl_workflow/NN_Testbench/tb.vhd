---------------------------------------------------------------------------------------------------
-- Simple FLI demo using named pipes
--
--
-- https://github.com/htminuslab            
--                                       
---------------------------------------------------------------------------------------------------
--                                                    
---------------------------------------------------------------------------------------------------
-- 
--  Revision History:                                                        
--                                                                           
--  Date:        Revision    Author         
--  01 Sep 2019  0.1         Hans Tiggeler 
--  19 May 2022  0.2         Hans Tiggeler  Added input string for pipename and checked with 2022.2
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg is
	function open_pipe(pipename:in string; timeout:in integer) return boolean;
	attribute FOREIGN of open_pipe : function is "open_pipe ./fli_pipe.dll";	

	procedure close_pipe;
	attribute FOREIGN of close_pipe : procedure is "close_pipe ./fli_pipe.dll";				
	
	procedure read_pipe(numread:out integer; vector:out string);
	attribute FOREIGN of read_pipe : procedure is "read_pipe ./fli_pipe.dll";	
end;

package body pkg is	
	function  open_pipe(pipename:in string; timeout:in integer) return boolean is begin return false; end;
	procedure close_pipe is begin end;
	procedure read_pipe(numread:out integer; vector:out string) is begin end;
end;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end tb;

use work.pkg.all;

architecture example of tb is
begin

	process
		variable retval_v : boolean;
		variable numread : integer;
		variable vector_v : string(1 to 128):=(others => '0');	
	begin
		retval_v:=open_pipe("\\.\pipe\LogPipe",300);	-- Name of the pipe and timeout delay in seconds	
		assert (retval_v) report("Failed to open pipe") severity failure;
		wait for 1 ns;
	
		loop	
			read_pipe(numread, vector_v);				-- Read Vector
			if numread>0 then
				report("Receiving vector "& vector_v);
				exit when vector_v(1)='Q';				-- Terminate
			end if;
			wait for 1 ns;
		end loop;
	
		close_pipe;										-- Clean up
		wait;
	end process;

end;

