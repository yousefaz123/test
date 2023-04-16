<?php
// Get the language and code from the form
$language = $_POST['language'];
$code = $_POST['code'];

// Compile the code
switch($language) {
case 'java':
exec("javac $code");
break;
case 'js':
exec("node $code");
break;
case 'python':
exec("python $code");
break;
case 'html':
echo $code;
break;
}
?>

