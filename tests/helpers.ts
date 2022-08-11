export function sleep(seconds: number) {
    console.log(`Waiting ${seconds} seconds`)
    return new Promise((resolve) => setTimeout(resolve, seconds * 1000))
}

export async function mineBlock(provider: any) {
    await provider.send('evm_mine', [])
}

export async function setNextBlockTimestamp(provider: any, timestamp: number) {
    await provider.send('evm_setNextBlockTimestamp', [timestamp])
    await provider.send('evm_mine', [])
}

export async function mineBlocks(blockNumber: number, provider: any) {
    while (blockNumber > 0) {
        blockNumber--;
        await provider.send('evm_mine', [])
    }
}