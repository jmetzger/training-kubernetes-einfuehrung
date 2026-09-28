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
