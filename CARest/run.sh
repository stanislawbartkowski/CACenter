source envr.rc
JAR=target/CARestApi-1.0-SNAPSHOT-jar-with-dependencies.jar
java -cp $JAR RestMain -c carest.properties -p $PORT
