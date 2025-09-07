# 🚨 CrisisWatch: Decentralized Crisis Reporting Platform

Welcome to CrisisWatch, a Web3 platform built on the Stacks blockchain that empowers citizens to report real-time crises (like natural disasters, conflicts, or public emergencies) with token incentives. By leveraging blockchain for transparent validation, it solves the real-world problem of misinformation and delayed situational awareness during crises, ensuring accurate, crowdsourced intelligence that can aid responders, journalists, and communities.

## ✨ Features

🔥 Citizen-reported crises with on-chain submissions for immutability  
💰 Token rewards for accurate reporting and validation to incentivize participation  
✅ Community-driven validation to filter out fake news  
📍 Geolocation hashing for verifiable incident locations  
🛡️ Reputation system to build trust in reporters and validators  
📊 Queryable dashboard data for real-time crisis analytics  
⚖️ Dispute resolution for contested reports  
🔒 Secure token staking for validators to prevent sybil attacks  

## 🛠 How It Works

**For Reporters**  
- Witness a crisis? Submit details (description, location hash, evidence hashes) via the reporting contract.  
- Your submission is timestamped on-chain for proof of timeliness.  
- If validated by the community, earn CRISIS tokens as a reward.  

**For Validators**  
- Stake tokens to participate in validation pools.  
- Review submissions, vote on authenticity, and provide counter-evidence if needed.  
- Accurate validations earn rewards; incorrect ones slash stakes for accountability.  

**For Users/Responders**  
- Query verified reports for real-time insights.  
- Use governance to propose system improvements, like reward adjustments.  

The platform uses token incentives to encourage honest reporting: Reporters get bounties for validated crises, validators share in rewards, and the system self-sustains through a small submission fee redistributed as incentives. This creates accurate situational awareness, reducing reliance on centralized (and potentially biased) news sources.

## 📜 Smart Contracts

This project involves 8 smart contracts written in Clarity, ensuring modularity, security, and composability on the Stacks blockchain. Here's an overview:

1. **CrisisToken.clar** (SIP-010 Fungible Token)  
   - Manages the CRISIS token for incentives.  
   - Functions: mint, transfer, burn, balance-of.  
   - Used for rewards, staking, and fees.

2. **ReportSubmission.clar**  
   - Handles crisis report creation.  
   - Functions: submit-report (with hash, description, location), get-report-details.  
   - Emits events for new submissions to trigger validations.

3. **ValidationPool.clar**  
   - Manages validator staking and assignment to reports.  
   - Functions: stake-tokens, unstake, assign-validators (random selection via VRF if integrated).  
   - Ensures validators have skin in the game.

4. **ValidationVoting.clar**  
   - Enables voting on report authenticity.  
   - Functions: vote-valid, vote-invalid, tally-votes.  
   - Uses time-locked voting periods to finalize outcomes.

5. **RewardDistributor.clar**  
   - Calculates and distributes tokens based on validation results.  
   - Functions: claim-reward, distribute-bounty.  
   - Rewards reporters for valid reports and validators for correct votes; slashes for malice.

6. **DisputeResolution.clar**  
   - Handles challenges to validated reports.  
   - Functions: file-dispute, resolve-dispute (via super-validators or oracle).  
   - Provides a second layer of arbitration for high-stakes cases.

7. **ReputationSystem.clar**  
   - Tracks user reputation scores.  
   - Functions: update-reputation, get-reputation.  
   - Boosts rewards for high-rep users and restricts low-rep ones from validating.

8. **Governance.clar**  
   - Allows token holders to vote on parameters (e.g., reward rates, validation thresholds).  
   - Functions: propose-change, vote-proposal, execute-proposal.  
   - Ensures decentralized evolution of the platform.

## 🚀 Getting Started

To deploy: Clone the repo, install Clarity tools, and deploy contracts in order (starting with CrisisToken). Integrate with a frontend dApp for user interactions. Test on Stacks testnet for crisis simulations!

This idea promotes global transparency in crisis response—join the revolution! 🚀