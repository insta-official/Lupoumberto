<?php
// Inserisci qui l'URL da aprire tramite proxy (può anche essere preso da $_GET['url'] o simili)
$url = isset($_GET['url']) ? $_GET['url'] : 'https://www.repubblica.it';

// Includi il core di PHP-Proxy
require_once 'proxy/vendor/autoload.php';

use Proxy\Http\Request;
use Proxy\Http\Response;
use Proxy\Proxy;
use Proxy\Event\ProxyEvent;

// Configura il Proxy
$request = Request::createFromGlobals();
$request->get->set('url', $url); // forza l’URL da caricare

$response = new Response();

$proxy = new Proxy();

// Eventi (opzionali, per personalizzazioni avanzate)
$proxy->getEventDispatcher()->addListener('request.before_send', function (ProxyEvent $event) {
    // Esempio: modifica header o logga richieste
});

// Avvia il proxy
$response = $proxy->forward($request)->toResponse();

$response->send();
