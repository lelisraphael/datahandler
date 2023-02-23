# How to run the app
----------------------------------------------
----------------------------------------------

# For create Docker app imagem
docker-compose up . 

# Access the docker bash
docker-compose run geatec-app bash

# Run migrate
rails db:migrate
----------------------------------------------
----------------------------------------------

# Extra commands
# Create seeds with mocked data
rails db:seed

# Drop database
rails db:drop

# Create database
rails db:create
