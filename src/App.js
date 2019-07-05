import React, { Component } from 'react'
import logo from './logo.svg';
import './App.css';

import {
  CryptoUtils,
  LoomProvider,
  LocalAddress,
  Client,
  Address,
  NonceTxMiddleware,
  SignedTxMiddleware,
  // commitTxAsync,
  // SignedEthTxMiddleware,
  // createDefaultTxMiddleware,
  // SpeculativeNonceTxMiddleware,
  // CachedNonceTxMiddleware,
  // SuperSimpleMiddlware,
  // DuplicateNonceTxMiddleware
} from 'loom-js'

import Web3 from 'web3'

import ERC223Token from './contracts/ERC223Token.json'
// 0x0ddedc5AD88b2d3633c4470126ED7F8E34235682

class App extends Component {

  constructor(props) {
    super(props)
    this.state = {
      pending: true,

      // LOOM VARIABLES
      callerChainId: 'eth',
      chainId: 'extdev-plasma-us1',
      writeUrl: 'wss://extdev-plasma-us1.dappchains.com/websocket',
      readUrl: 'wss://extdev-plasma-us1.dappchains.com/queryws',
      loomGatewayAddress: '0xE754d9518bF4a9C63476891eF9Aa7D91c8236a5d',
      mainNetGatewayAddress: '0xb73C9506cb7f4139A4D6Ac81DF1e5b6756Fab7A2',
      networkId: "9545242630824",

      web3: null,
      loomProvider: null,
      loomPublicAddress: null,
      loomAddress: null,
      publicKey: null,
      nonceCount: 0,
      balance: null,
      amount: null,

      loomTokenContract: {},

    }
    this.getFreeTokens = this.getFreeTokens.bind(this);
    this.transferTokens = this.transferTokens.bind(this);
  }

  async componentDidMount() {
    if (await this.init()) {
      await this.initTokenState()
    }
  }

  async init() {
    const { chainId, writeUrl, readUrl } = this.state;
    const privateKey = await this.getPrivateKey()
    const publicKey = CryptoUtils.publicKeyFromPrivateKey(privateKey)
    const loomPublicAddress = LocalAddress.fromPublicKey(publicKey).toString()
    const loomAddress = new Address(chainId, loomPublicAddress)

    this.client = new Client(chainId, writeUrl, readUrl)
    // this.client.txMiddleware = [
    //   new NonceTxMiddleware(publicKey, this.client),
    //   new SignedTxMiddleware(privateKey)
    // ]

    const web3 = new Web3(new LoomProvider(this.client, privateKey))

    this.setState({ publicKey, loomPublicAddress, loomAddress, web3 })

    return true
  }

  async initTokenState() {
    let { web3, networkId, loomTokenContract, loomPublicAddress } = this.state;

    loomTokenContract = new web3.eth.Contract(
      ERC223Token.abi,
      ERC223Token.networks[networkId].address, { loomPublicAddress }
    )

    // INITIAL BALANCE SHOULD BE 0
    const balance = web3.utils.fromWei(await loomTokenContract.methods.balanceOf(loomPublicAddress).call({ from: loomPublicAddress }), "ether")
    console.log(balance);

    this.setState({ loomTokenContract, balance })
  }

  async getFreeTokens() {
    const { loomTokenContract, loomPublicAddress } = this.state;

    const getFreeTokens = await loomTokenContract.methods.getFreeTokens().send({ from: loomPublicAddress })
    console.log("Get Free Tokens:", getFreeTokens);
  }

  async transferTokens() {
    const { web3, loomTokenContract, loomPublicAddress } = this.state;
    const address2 = '0x46beC6147E1bD4467c32A513E46a182672E0B469';

    const amount = web3.utils.toWei("100", "ether")
    const sendTokens = await loomTokenContract.methods.transfer(address2, amount, "0x").send({ from: loomPublicAddress })
    console.log(sendTokens);

  }

  async getPrivateKey() {
    let privateKey = localStorage.getItem('loom_pk')
    if (!privateKey) {
      privateKey = CryptoUtils.generatePrivateKey()
      localStorage.setItem('loom_pk', JSON.stringify(Array.from(privateKey)))
    } else {
      privateKey = new Uint8Array(JSON.parse(privateKey))
    }
    return privateKey
  }

  render() {
    const { balance } = this.state;
    return (
      <div className="App">
        <header className="App-header">
          <img src={logo} className="App-logo" alt="logo" />
          <p>
            Balance: {balance} Tokens
          </p>
          <div style={{ width: "100%" }}>

            <button className="App-link" onClick={this.getFreeTokens}>
              Get Free Tokens
            </button>

            <button className="App-link" onClick={this.transferTokens} style={{ marginLeft: "10px" }}>
              Transfer Tokens
            </button>

          </div>
        </header>
      </div>
    );
  }
}

export default App;