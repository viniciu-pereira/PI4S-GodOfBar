<?php
require __DIR__ . '/../vendor/autoload.php';

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

$app = AppFactory::create();

// Middleware para adicionar cabeçalhos CORS e permitir apenas o método GET
$app->add(function (Request $request, $handler) {
    if ($request->getMethod() !== 'GET') {
        $response = new \Slim\Psr7\Response();
        return $response->withStatus(405)->withHeader('Content-Type', 'application/json')
                        ->withHeader('Access-Control-Allow-Origin', '*')
                        ->withHeader('Access-Control-Allow-Methods', 'GET')
                        ->withBody((new \Slim\Psr7\Stream(fopen('php://temp', 'r+')))
                        ->write(json_encode(['error' => 'Method Not Allowed'])));
    }
    $response = $handler->handle($request);
    return $response
        ->withHeader('Access-Control-Allow-Origin', '*')
        ->withHeader('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Accept, Origin, Authorization')
        ->withHeader('Access-Control-Allow-Methods', 'GET');
});

// Rota para obter os dados de temperatura
$app->get('/temperature', function (Request $request, Response $response, $args) {
    $servername = $_ENV['DB_SERVER'];
    $username = $_ENV['DB_USERNAME'];
    $password = $_ENV['DB_PASSWORD'];
    $dbname = $_ENV['DB_NAME'];

    try {
        $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Consulta com limite de resultados
        $stmt = $conn->prepare("SELECT * FROM temperature_data ORDER BY timestamp DESC LIMIT 100");
        $stmt->execute();

        // Retornar resultados como JSON com temperaturas formatadas
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Formatando temperaturas
        foreach ($results as &$result) {
            $result['temperature'] = number_format((float)$result['temperature'], 2, '.', '');
        }

        $payload = json_encode($results);
        $response->getBody()->write($payload);
        return $response->withHeader('Content-Type', 'application/json');
    } catch(PDOException $e) {
        $errorPayload = json_encode(['error' => "Erro: " . $e->getMessage()]);
        $response->getBody()->write($errorPayload);
        return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
    }
});

$app->run();
