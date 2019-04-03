package io.stormbird.wallet.repository;

import io.reactivex.disposables.Disposable;
import io.stormbird.wallet.entity.*;

import java.math.BigInteger;
import java.util.List;

import io.reactivex.Completable;
import io.reactivex.Observable;
import io.reactivex.Single;
import io.stormbird.wallet.service.AssetDefinitionService;

public interface TokenRepositoryType {

    Observable<Token[]> fetchActiveStored(String walletAddress);
    Observable<Token[]> fetchActiveStoredPlusEth(String walletAddress);
    Observable<Token> fetchActiveSingle(String walletAddress, Token token);
    Observable<Token> fetchCachedSingleToken(NetworkInfo network, String walletAddress, String tokenAddress);
    Observable<Token> fetchActiveTokenBalance(String walletAddress, Token token);
    Single<ContractResult> getTokenResponse(String address, int chainId, String method);
    Completable setEnable(Wallet wallet, Token token, boolean isEnabled);
    Observable<TokenInfo> update(String address, int chainId);
    Single<TokenInfo[]> update(String[] address, NetworkInfo network);
    Disposable memPoolListener(int chainId, SubscribeWrapper wrapper); //only listen to transactions relating to this address
    Observable<TransferFromEventResponse> burnListenerObservable(String contractAddress);
    Single<Token> addToken(Wallet wallet, TokenInfo tokenInfo, ContractType interfaceSpec);
    Single<Token> callTokenFunctions(Token token, AssetDefinitionService service);
    Single<Ticker> getEthTicker(int chainId);
    Single<Token> getEthBalance(NetworkInfo network, Wallet wallet);
    Single<BigInteger> fetchLatestBlockNumber(int chainId);

    Disposable terminateToken(Token token, Wallet wallet, NetworkInfo network);

    Single<Token[]> addERC721(Wallet wallet, Token[] tokens);
    Single<String> callAddressMethod(String method, byte[] resultHash, String address);

    Disposable updateBlockRead(Token token, Wallet wallet);
    Single<String> resolveProxyAddress(TokenInfo tokenInfo);
}
