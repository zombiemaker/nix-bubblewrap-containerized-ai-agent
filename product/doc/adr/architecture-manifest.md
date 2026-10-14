# Architectural Manifest & Spec Index

This repository enforces an automated, agent-compliant design framework. All development tools and engineers must adhere to the chained specifications below:

## Core Ground Truth
* **[Repository Directory Standard](./adr-0001-repository-directory-standard.md):** Defines file system isolation boundaries, language runtimes, and component lifecycle directory requirements.

## System Components & Protocols
* **[API Gateway Specification](./adr-0002-api-wire-protocol.md):** Must implement its logic *strictly* within `product/code/go-linux/api_gateway/production/`.
* **[Client API Protocol](./adr-0005-client-generation.md):** Governs how libraries under `product/code/*/*_client_api/` handle data bindings.
