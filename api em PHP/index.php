<?php

//Carrega as dependencias
require __DIR__ . '/../vendor/autoload.php';

//use -> importa as classes necessarias e o framework slim
    //Slim -> rest http para o php
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;
use Slim\Psr7\Response as SlimResponse;
use Slim\Psr7\Stream as SlimStream;

//Carregando o arquivo .env com os dados do banco
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

//Inicia a comunicação do slim
$app = AppFactory::create();

// Adiciona o CORS e permite apenas o método GET
$app->add(function (Request $request, $handler) {
    $method = $request->getMethod();

    //Verificação se o metodo é realmente get
    if ($method !== 'GET') {
        $response = new SlimResponse();
        $body = new SlimStream(fopen('php://temp', 'r+'));
        $body->write(json_encode(['error' => 'Method Not Allowed']));
        return $response
            //Se não for o get, retorna o erro 405
            ->withStatus(405)
            ->withHeader('Content-Type', 'application/json')
            ->withHeader('Access-Control-Allow-Origin', '*')
            ->withHeader('Access-Control-Allow-Methods', 'GET')
            ->withBody($body);
    }

    //htaccess
    $response = $handler->handle($request);
    return $response
        ->withHeader('Access-Control-Allow-Origin', '*')
        ->withHeader('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Accept, Origin, Authorization')
        ->withHeader('Access-Control-Allow-Methods', 'GET');
});

// Cria a rota consulta para obter os dados de temperatura do banco
$app->get('/consulta', function (Request $request, Response $response, $args) {
    $servername = $_ENV['DB_SERVER'];
    $username = $_ENV['DB_USERNAME'];
    $password = $_ENV['DB_PASSWORD'];
    $dbname = $_ENV['DB_NAME'];

    //Try catch para teste da conexão ao banco e busca sql
    try {
        $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Consulta no banco
        $stmt = $conn->prepare("SELECT * FROM temperature_data ORDER BY timestamp DESC LIMIT 100");
        $stmt->execute();

        // Retorna os resultados como json(Array associativo -> Tipos diferentes, onde cada linha tem um formato diferente)
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Formatando temperaturas (bug de envio do arduino fez com q a temperatura precisasse ser float)
        foreach ($results as &$result) {
            $result['temperature'] = number_format((float)$result['temperature'], 2, '.', '');
        }

        //transforma a resposta em json 
        $payload = json_encode($results);
        $response->getBody()->write($payload);
        return $response->withHeader('Content-Type', 'application/json');
    } catch (PDOException $e) {
        
        //Envio para o arquivo de errorlog.txt do servidor
        error_log($e->getMessage());
        $errorPayload = json_encode(['error' => 'Internal Server Error']);
        $response->getBody()->write($errorPayload);
        //Envio de resposta de erro de comunicação interna em qualquer etapa do payload
        return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
    }
});

//Acesso da aplicação no servidor pela rota dominio/consulta.php
$app->run();
