# Uebung: Java REST-API mit Multi-Stage Dockerfile

## Hintergrund

Ein Multi-Stage-Build trennt das **Bauen** einer Anwendung vom **Ausfuehren**:

* Stage 1 (`build`): enthaelt den vollen JDK-Compiler, uebersetzt den Java-Code
* Stage 2: enthaelt nur ein schlankes JRE + die fertige `.class`-Datei

Der Compiler, Quellcode und alle Build-Tools landen NICHT im finalen Image - das Image
wird kleiner und hat eine kleinere Angriffsflaeche.

## Schritt 1: Verbindung zum Docker-Host

```
ssh -i ~/.ssh/id_ed25519_nopass root@docker11.t3isp.de
```

## Schritt 2: Arbeitsverzeichnis anlegen

```
mkdir -p ~/java-api-<dein-name>
cd ~/java-api-<dein-name>
```

## Schritt 3: Die REST-API (Main.java)

Kein Framework, kein Maven noetig - nur der eingebaute `com.sun.net.httpserver` aus dem
JDK. Zwei Endpunkte: `/api/health` und `/api/hello`.

```
# vi Main.java
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.InetAddress;
import java.nio.charset.StandardCharsets;

public class Main {

    public static void main(String[] args) throws IOException {
        int port = 8080;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/api/health", new HealthHandler());
        server.createContext("/api/hello", new HelloHandler());

        server.setExecutor(null);
        server.start();
        System.out.println("REST API laeuft auf Port " + port);
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String json = "{\"status\":\"UP\"}";
            sendJson(exchange, 200, json);
        }
    }

    static class HelloHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String host = "unknown";
            try {
                host = InetAddress.getLocalHost().getHostName();
            } catch (Exception e) {
                // ignore, bleibt "unknown"
            }
            String json = "{\"message\":\"Hallo von Java!\",\"host\":\"" + host + "\"}";
            sendJson(exchange, 200, json);
        }
    }

    static void sendJson(HttpExchange exchange, int status, String json) throws IOException {
        byte[] body = json.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, body.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(body);
        }
    }
}
```

## Schritt 4: Das Multi-Stage Dockerfile

```
# vi Dockerfile
# Stage 1: Build - hier steht der komplette JDK-Compiler zur Verfuegung
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY Main.java .
RUN javac Main.java

# Stage 2: Runtime - nur die fertige .class-Datei + schlankes JRE
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/Main*.class .
EXPOSE 8080
CMD ["java", "Main"]
```

**Wichtig:** `javac` erzeugt fuer jede innere Klasse eine eigene `.class`-Datei
(`Main.class`, `Main$HealthHandler.class`, `Main$HelloHandler.class`). Deshalb im
`COPY --from=build` das Muster `Main*.class` verwenden, nicht nur `Main.class` - sonst
startet der Container mit `NoClassDefFoundError`.

## Schritt 5: Image bauen

```
docker build -t java-api-<dein-name>:1.0 .
```

## Schritt 6: Container starten

Auf dem geteilten Docker-Host wuerden feste Ports (`-p 8080:8080`) zwischen den
Teilnehmern kollidieren. Deshalb den Host-Port von Docker zufaellig vergeben lassen:

```
docker run -d --name java-api-<dein-name> -p 8080 java-api-<dein-name>:1.0
docker port java-api-<dein-name> 8080/tcp
```

## Schritt 7: API testen

Den Port aus Schritt 6 einsetzen:

```
curl http://localhost:<port>/api/health
curl http://localhost:<port>/api/hello
```

Erwartete Ausgabe:

```
{"status":"UP"}
{"message":"Hallo von Java!","host":"<container-id>"}
```

## Schritt 8 (optional): Groessenvergleich mit Single-Stage

Zum Vergleich ein Image ohne Multi-Stage bauen (JDK + Compiler bleiben mit drin):

```
# vi Dockerfile.singlestage
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /app
COPY Main.java .
RUN javac Main.java
EXPOSE 8080
CMD ["java", "Main"]
```

```
docker build -f Dockerfile.singlestage -t java-api-<dein-name>-singlestage:1.0 .
docker images java-api-<dein-name>
docker images java-api-<dein-name>-singlestage
```

Im Test (docker11.t3isp.de, `eclipse-temurin:21-*-alpine`): Multi-Stage-Image ca. **74 MB**,
Single-Stage-Image ca. **184 MB** - mehr als doppelt so gross, nur weil Compiler und
Build-Werkzeuge mitgeschleppt werden.

## Aufraeumen

```
docker rm -f java-api-<dein-name>
docker rmi java-api-<dein-name>:1.0 java-api-<dein-name>-singlestage:1.0
```
