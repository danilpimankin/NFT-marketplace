const ethers = hre.ethers

async function main() {
    // const baseTokenUri = "ipfs://bafkreifoxg4mux3oourrrambpykjrayyv7k3c23fi4vwe567wbg4inghpy"
    const Market = await ethers.getContractFactory('Marketplace')
    const market = await Market.deploy(`${process.env.ERC20}`)

    await market.deployed()

    console.log("Contract's address: ", market.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });