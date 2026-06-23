FROM eclipse-temurin:11-jre
EXPOSE 9000
ARG JAR_FILE=target/student-service.jar
COPY ${JAR_FILE} student-service.jar
ENTRYPOINT [ "java", "-jar", "/student-service.jar" ]