all: compile exe

compile:
	ozc -c GUI.oz Input.oz Main.oz PlayerXXXMyCustomName.oz PlayerManager.oz

exe:
	ozengine Main.ozf

clean:
	rm *.ozf
