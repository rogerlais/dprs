
FOR /F "tokens=1,3 delims=," %A IN (setores.csv) DO runas /savecred /user:tre-pb\admlauricio "dsmod user "CN=%A,CN=users,dc=tre-pb,dc=gov,dc=br" -email \"%B\""