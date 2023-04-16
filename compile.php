<?php

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get the language and code from the form submission
    $language = $_POST['language'];
    $code = $_POST['code'];

    // Compile the code based on the selected language
    switch ($language) {
        case 'java':
            // Compile Java code
            $output = shell_exec("javac Main.java 2>&1");
            if (!$output) {
                $output = shell_exec("java Main 2>&1");
            }
            break;

        case 'js':
            // Compile JavaScript code
            $output = shell_exec("node Main.js 2>&1");
            break;

        case 'python':
            // Compile Python code
            $output = shell_exec("python Main.py 2>&1");
            break;

        case 'html':
            // Compile HTML code
            $output = shell_exec("open index.html");
            break;

        default:
            // Invalid language selection
            $output = "Invalid language selection";
            break;
    }

    // Print the output of the compilation process
    echo "<pre>$output</pre>";
}

?>
