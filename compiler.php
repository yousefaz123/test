<?php
// get the user's code and language selection from the form
$userCode = $_POST['code'];
$language = $_POST['language'];

// determine which command to use based on the selected language
switch ($language) {
    case 'java':
        $command = 'javac Main.java && java Main';
        $filename = 'Main.java';
        break;
    case 'js':
        $command = 'node index.js';
        $filename = 'index.js';
        break;
    case 'python':
        $command = 'python main.py';
        $filename = 'main.py';
        break;
    case 'html':
        // display the HTML code as text
        echo "<pre>$userCode</pre>";
        exit();
        break;
    default:
        die('Error: Invalid language selection.');
}

// create a file with the user's code
file_put_contents($filename, $userCode);

// execute the command to compile and run the code
$output = shell_exec($command);

// display the output
echo "<pre>$output</pre>";

// remove the file containing the user's code
unlink($filename);
?>
