# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [UNRELEASED] - 0000-00-00

## [0.1.0] - 2022-12-10
### Added
- Add MySQL schema, migrations, models for Applications, Applications chats, and Applications chats messages.
- Add RabbitMQ handlers (RPC server), and unit tests for:
    * Applications create, and update.
    * Applications chats create.
    * Applications chats messages create, and update.
- Add race conditions tests for Applications chats create, and Applications chats messages create.
- Add Dockerfile.
