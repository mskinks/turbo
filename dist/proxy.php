<?php

// Just a simple proxy to get the F-List API ticket (bypasses CORS security).

$url = "https://www.f-list.net/json/getApiTicket.php";
$data = $_POST;

$options = array(
    'http' => array(
        'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
        'method'  => 'POST',
        'content' => http_build_query($data),
         )
     );

$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);

header('Content-Type: application/json');
print($result);
