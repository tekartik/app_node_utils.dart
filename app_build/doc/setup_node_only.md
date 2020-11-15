## Setup for nodejs only development

- Follow [setup](setup.md)
- Create a dart_test.yaml:
    ```yaml
    # This package's tests are very slow. Double the default timeout.
    timeout: 2x
    
    # This is a node-only package, so test on node.
    platforms: [node]
    ```

