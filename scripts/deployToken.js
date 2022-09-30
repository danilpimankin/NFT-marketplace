const ethers = hre.ethers

async function main() {
    const Token = await ethers.getContractFactory('Token')
    const token = await Token.deploy()

    await token.deployed()

    console.log("Contract's address: ", token.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });