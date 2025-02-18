mod utils;
use utils::get_token0_n_1;
use starknet::ContractAddress;
use snforge_std::{declare, DeclareResultTrait, ContractClassTrait};

use contracts::contract::interface::UniswapV3PoolTraitDispatcher;
use contracts::contract::interface::UniswapV3PoolTraitDispatcherTrait;

#[derive(Drop)]
struct TestParams {
    strk_balance: u128, // balance in strk (P = x/y)
    usdc_balance: u128, //balance in usdc 
    cur_tick: i32,
    lower_tick: i32,
    upper_tick: i32,
    liq: u256,
    cur_sqrtp: u256,
    mint_liquidity: bool,
}

trait TestParamsT<T> {
    fn test1params() -> TestParams;
}

impl TestParamsImpl of TestParamsT<TestParams> {
    fn test1params() -> TestParams {
        TestParams {
            strk_balance: 1000000,
            usdc_balance: 225398,
            cur_tick: -15372,
            lower_tick: -15900,
            upper_tick: -14880,
            liq: 5670207847624064000,
            cur_sqrtp: 36736587662821057944650860901,
            mint_liquidity: true,
        }
    }
}

fn deploy_contract(name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_mint_liquidity_using_params() {
    let params = TestParamsImpl::test1params();
    let (token0, token1) = get_token0_n_1();


    let calldata: Array<felt252> = array![
        token0.into(),
        token1.into(),
        params.cur_sqrtp.try_into().unwrap(),      // Use current sqrt price from test params
        0.into(),                     // Adjust or compute as needed (could also be derived from params)
        params.cur_tick.into()        // Use current tick from test params
    ];

    // Deploy the contract with the provided test parameters
    let pool_contract_address = deploy_contract("UniswapV3Pool", calldata);
    let mut dispatcher = UniswapV3PoolTraitDispatcher { contract_address: pool_contract_address };

    // Verify initial liquidity is zero
    let liquidity_before = dispatcher.get_liquidity();
    println!("liquidity before: {:?}", liquidity_before);
    assert(liquidity_before == 0, 'Invalid liquidity before mint');

    // Use the lower_tick, upper_tick, and liquidity from test parameters.
    dispatcher.mint(params.lower_tick, params.upper_tick, params.liq.try_into().unwrap());

    // Check liquidity after mint to ensure it matches expected amount
    let liquidity_after = dispatcher.get_liquidity();
    println!("liquidity after: {:?}", liquidity_after);
    assert(liquidity_after == params.liq.into(), 'Invalid liquidity after mint');
}
