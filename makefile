all: compile exe

compile:
	ozc -c GUI.oz Input.oz Main.oz Player033Basic.oz PlayerManager.oz Player033Advanced.oz
exe:
	ozengine Main.ozf

clean:
	rm *.ozf
