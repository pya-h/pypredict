import { useState } from "react";
import styles from "../components.module.css";
import { ethers } from "ethers";
import predictionMarketContract from "../../blockchain.json";

export default function ConnectWallet() {
  const [error, setError] = useState(null);

  const connectToWallet = async () => {
    if (typeof window.ethereum === "undefined") {
      setError("Metamask is not installed.");
      return;
    }
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const walletAddress = await signer.address();
      const predictionMarket = new ethers.Contract(
        predictionMarketContract.pmContractAddress,
        predictionMarketContract.pmContractABI,
        signer
      );

      const network = await provider.getNetwork();
      
    } catch (ex) {}
  };

  return (
    <div className={styles.ConnectWallet}>
      <button onClick={connectToWallet}>Connect Wallet</button>
    </div>
  );
}
