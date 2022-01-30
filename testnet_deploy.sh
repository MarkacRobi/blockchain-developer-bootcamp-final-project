if [ ! -f .env ]
then
  export $(cat .env | xargs)
fi

npx hardhat run scripts/deploy.js --network rinkeby