all: zxbrainfuck

zxbrainfuck: loader.tap main.tap brainfuck.tap
		cat loader.tap main.tap brainfuck.tap > zxbrainfuck.tap

loader.tap: loader.bas
		bas2tap.exe -a10 -sLoader loader.bas loader.tap

main.tap: main.asm
		pasmo.exe -v --tap --err main.asm main.tap

brainfuck.tap: brainfuck.asm
		pasmo.exe -v --tap --err brainfuck.asm brainfuck.tap

brainfuck:
ifeq (${SOURCE},)
		@echo "Error: Please run with \"make brainfuck SOURCE=soucefile.bf\""
else
		python bf2data.py ${SOURCE} > brainfuck.asm
endif

clean:
		rm -rf *.tap

clean-all: clean
		rm -rf brainfuck.asm