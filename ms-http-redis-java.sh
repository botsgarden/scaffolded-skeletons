#!/usr/bin/env bash

# usage
# ./ms-http-redis-java.sh -g org.typeunsafe -a plop -m Plop -p 5656 -s 4545

show_help() {
cat << EOF
Usage:
  -g: group id eg: "org.typeunsafe"
  -a: artifact id (project name, default: service)
  -m: main verticle name (class name, default: Service)
  -p: http port (default: 8080)
  -s: exposed http service port (default: 8080)
  -o: GitHub organization to push the repository (if not, the user is used) (*)
  -u: GitHub user (only if you don't use an organization)

(*): you need to set the environment variable GH_TOKEN with a personal web token

Samples:

./ms-http-redis-java.sh -o the-plan -a raider -m Raider
./ms-http-redis-java.sh -u k33g -a raider -m Raider
EOF
}

port=8080
serviceport=8080
groupid="org.typeunsafe"
artifactid="service"
mainverticle="Service"
currentrepo=""
organization=""
user=""

while getopts hg:a:m:p:s:o:u: opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    g) 
      groupid=$OPTARG
      ;;
    a) 
      artifactid=$OPTARG
      ;;     
    m) 
      mainverticle=$OPTARG
      ;;   
    p) 
      port=$OPTARG
      ;;
    s) 
      serviceport=$OPTARG
      ;;
    o)
      organization=$OPTARG
      ;;
    u)
      user=$OPTARG
      ;;
  esac
done


# usage ./ms-http-redis-java.sh <groupId> <artifactId> <main.verticle> <http-port|optional|default 8080> <service-port|optional|default 8080>

mkdir $artifactid
cd $artifactid

currentrepo=$(pwd)

mkdir -p src/{main,test}/{java,resources/webroot}

# about deployment
# on Clever Cloud https://www.clever-cloud.com/
mkdir clevercloud
cat > clevercloud/jar.json << EOF
{
  "build": {
    "type": "maven",
    "goal": "package"
  },
  "deploy": {
    "jarName": "target/$artifactid-1.0-SNAPSHOT-fat.jar"
  }
}
EOF


# index.html
cat > src/main/resources/webroot/index.html << EOF
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="x-ua-compatible" content="ie=edge">
    <title>$mainverticle</title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <style>
    .container
    {
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      text-align: center;
    }
    .title
    {
      font-family: "Source Sans Pro", "Helvetica Neue", Arial, sans-serif;
      display: block;
      font-weight: 300;
      font-size: 100px;
      color: #35495e;
      letter-spacing: 1px;
    }
    .subtitle
    {
      font-family: "Source Sans Pro", "Helvetica Neue", Arial, sans-serif;
      font-weight: 300;
      font-size: 42px;
      color: #526488;
      word-spacing: 5px;
      padding-bottom: 15px;
    }
    .links
    {
      padding-top: 15px;
    }
    </style>
  </head>
  <body>
    <section class="container">
      <div>
        <h1 class="title">
          $mainverticle
        </h1>
        <h2 class="subtitle">
          Vert-x microservice by $groupid
        </h2>
      </div>
    </section>
  </body>
</html>
EOF

# README.md
cat > README.md << EOF
# $mainverticle
EOF

# .gitignore
cat > .gitignore << EOF
.idea/
.vertx/
*.class
*.log
*.iml
.project
.classpath
.settings
.vscode
dump.rdb
target/
EOF

# build.sh
cat > build.sh << EOF
#!/usr/bin/env bash
mvn clean package
EOF

chmod +x build.sh

# run.sh
cat > run.sh << EOF
#!/usr/bin/env bash
PORT=$port SERVICE_PORT=$serviceport java  -jar target/$artifactid-1.0-SNAPSHOT-fat.jar
EOF


chmod +x run.sh

# pom.xml
cat > pom.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>$groupid</groupId>
  <artifactId>$artifactid</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <vertx.version>3.4.1</vertx.version>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <main.verticle>$groupid.$mainverticle</main.verticle>
  </properties>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.1</version>
        <configuration>
          <source>1.8</source>
          <target>1.8</target>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>2.3</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <manifestEntries>
                    <Main-Class>io.vertx.core.Launcher</Main-Class>
                    <Main-Verticle>\${main.verticle}</Main-Verticle>
                  </manifestEntries>
                </transformer>
                <transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                  <resource>META-INF/services/io.vertx.core.spi.VerticleFactory</resource>
                </transformer>
              </transformers>
              <artifactSet>
              </artifactSet>
              <outputFile>\${project.build.directory}/\${project.artifactId}-\${project.version}-fat.jar
              </outputFile>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>

  <dependencies>
    <dependency>
      <groupId>io.vertx</groupId>
      <artifactId>vertx-core</artifactId>
      <version>\${vertx.version}</version>
    </dependency>

    <dependency>
      <groupId>io.vertx</groupId>
      <artifactId>vertx-web</artifactId>
      <version>\${vertx.version}</version>
    </dependency>

    <dependency>
      <groupId>io.vertx</groupId>
      <artifactId>vertx-web-client</artifactId>
      <version>\${vertx.version}</version>
    </dependency>

    <dependency>
      <groupId>io.vertx</groupId>
      <artifactId>vertx-service-discovery</artifactId>
      <version>\${vertx.version}</version>
    </dependency>

    <dependency>
      <groupId>io.vertx</groupId>
      <artifactId>vertx-service-discovery-backend-redis</artifactId>
      <version>\${vertx.version}</version>
    </dependency>
  </dependencies>
</project>
EOF

packages=$(echo $groupid | tr "." "\n")
cd src/main/java
for package in $packages
do
  mkdir $package
  cd $package
done

# main verticle 
cat > $mainverticle.java << EOF
package $groupid;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Future;
import io.vertx.core.http.HttpServer;
import io.vertx.core.json.JsonObject;

import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.StaticHandler;
import io.vertx.ext.web.handler.BodyHandler;

import io.vertx.servicediscovery.types.HttpEndpoint;
import io.vertx.servicediscovery.ServiceDiscovery;
import io.vertx.servicediscovery.ServiceDiscoveryOptions;
import io.vertx.servicediscovery.Record;

import java.util.Optional;

public class $mainverticle extends AbstractVerticle {
  
  private ServiceDiscovery discovery;
  private Record record;

  // Settings to record the service
  private String serviceName = Optional.ofNullable(System.getenv("SERVICE_NAME")).orElse("$2");
  private String serviceHost = Optional.ofNullable(System.getenv("SERVICE_HOST")).orElse("localhost"); // domain name
  // this is the visible port from outside
  // for example you run your service with 8080 on a platform (Clever Cloud, Docker, ...)
  // and the visible port is 80
  private Integer servicePort = Integer.parseInt(Optional.ofNullable(System.getenv("SERVICE_PORT")).orElse("80")); // set to 80 on Clever Cloud
  private String serviceRoot = Optional.ofNullable(System.getenv("SERVICE_ROOT")).orElse("/api");

  private Integer httpPort = Integer.parseInt(Optional.ofNullable(System.getenv("PORT")).orElse("8080"));
  
  // Redis settings
  private Integer redisPort = Integer.parseInt(Optional.ofNullable(System.getenv("REDIS_PORT")).orElse("6379"));
  private String redisHost = Optional.ofNullable(System.getenv("REDIS_HOST")).orElse("127.0.0.1");
  private String redisAuth = Optional.ofNullable(System.getenv("REDIS_PASSWORD")).orElse(null);
  private String redisRecordsKey = Optional.ofNullable(System.getenv("REDIS_RECORDS_KEY")).orElse("vert.x.ms");  

  public void stop(Future<Void> stopFuture) {
    System.out.println("👋 bye bye " + record.getRegistration());
    discovery.unpublish(record.getRegistration(), ar -> {
      if(ar.succeeded()) {
        System.out.println("unpublished 😀");
        stopFuture.complete();
      } else {
        ar.cause().printStackTrace();
      }
    });
  }

  public void start() {

    HttpServer server = vertx.createHttpServer();
    Router router = Router.router(vertx);
    router.route().handler(BodyHandler.create());

    ServiceDiscoveryOptions serviceDiscoveryOptions = new ServiceDiscoveryOptions();
    // Mount the service discovery backend
    discovery = ServiceDiscovery.create(
      vertx,
      serviceDiscoveryOptions.setBackendConfiguration(
        new JsonObject()
          .put("host", redisHost)
          .put("port", redisPort)
          .put("auth", redisAuth)
          .put("key", redisRecordsKey)
      ));

    // create the microservice record
    record = HttpEndpoint.createRecord(
      serviceName,
      serviceHost,
      servicePort,
      serviceRoot
    );

    record.setMetadata(new JsonObject()
      .put("message", "Hello 🌍")
      .put("uri", "/ping")
    );

    discovery.publish(record, res -> {
      System.out.println("😃 published! " + record.getRegistration());
    });

    router.post("/api/ping").handler(context -> {
      // before, you should test that context is not null
      String name = Optional.ofNullable(context.getBodyAsJson().getString("name")).orElse("John Doe");
      System.out.println("🤖 called by " + name);

      context.response()
        .putHeader("content-type", "application/json;charset=UTF-8")
        .end(
          new JsonObject().put("message", "👋 hey "+ name + " 😃").toString()
        );
    });

    router.get("/api/ping").handler(context -> {
      context.response()
        .putHeader("content-type", "application/json;charset=UTF-8")
        .end(
          new JsonObject().put("message", "🏓 pong!").toString()
        );
    });

    // serve static assets, see /resources/webroot directory
    router.route("/*").handler(StaticHandler.create());

    server.requestHandler(router::accept).listen(httpPort, result -> {
      System.out.println("🌍 Listening on " + httpPort);
    });

  }
}
EOF

# === create a git repository

#echo "$currentrepo"
cd $currentrepo
#pwd
git init
git add .
git status
git commit -m "🚀 first version"


# Create GitHub repository
data="{\"name\":\""$artifactid"\"}"

if [[ -z $organization ]]; then
  curl -H "Authorization: token $GH_TOKEN" --data $data https://api.github.com/user/repos
  git remote add origin https://github.com/$user/$artifactid.git
else
  curl -H "Authorization: token $GH_TOKEN" --data $data https://api.github.com/orgs/$organization/repos
  git remote add origin https://github.com/$organization/$artifactid.git
fi

git push -u origin master