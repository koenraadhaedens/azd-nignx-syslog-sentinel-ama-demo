Under Construction. All help is welcome. Just fork, make changes and do a pull request


# Azure Sentinel Syslog Demo with NGINX and AMA

This guide walks through setting up a demo environment to send NGINX logs from a Linux VM to Microsoft Sentinel using the AMA (Azure Monitor Agent), then parsing and alerting with Sentinel Analytics Rule.

---

## 🧩 Prerequisites

- Azure subscription with owner/contributor permissions


---

## ✅ Step 1 – Deploy Microsoft Sentinel Environment

(you can also do the demo without Sentinel just using log analytics)

Go to Azure Cloud Shell (click the CloudShell icon on the top right in azure, you can use both Bash or PowerShell)

go to https://microsoftlearning.github.io/trainer-demo-deploy/ and find Azure Sentinel with Data Connectors


```bash
# Example command (adjust to your lab tooling)
azd init -t petender/azd-sentinel
azd up
```



---

## ✅ Step 2 – Deploy Demo Environment (NGINX + Syslog VMs)

Deploy the NGINX web proxy and syslog VM using the demo template.
You don't have to wait for the Sentinel deployment to complete — you can open a new browser tab and go to https://shell.azure.com to continue working.

Type Commands below and follow prompts. Use same region as choosen for Sentinel

```bash
mkdir 2
cd 2
azd init -t koenraadhaedens/azd-nignx-syslog-sentinel-ama-demo
azd up
```


Verify that:
- Sentinel is enabled on the Log Analytics workspace
- A workspace is provisioned and connected
- VM `nginx-vm-<deploymentname>` is created with a demo site and open port 443
- VM `syslog-vm-<deploymentname>` is created and ready to receive syslog
- `nginx-vm` is configured to forward syslog messages to `syslog-vm` over UDP/514

---

## ✅ Step 3 – Validate Syslog Flow

1. **Temporarily open port 22** on the `syslog-vm-xxx` from your IP:
   - Use Azure Portal :
   Find Syslog Virtual machine, got to the Network setting and add ncoming Rule to open SSH only from your public ip, I recomend using JIT from server protection workload in Defender for Cloud.


2. **SSH into the syslog VM**:

   ```bash
   ssh azureuser@<syslog-vm-public-ip>
   ```

3. **Tail syslog messages**:

   ```bash
   sudo tail -f /var/log/syslog
   ```

4. In your browser, **refresh the HTTPS demo website** hosted on `nginx-vm`.

   - You should see new access log entries (in syslog format) appearing in the `syslog-vm` terminal.

---

## ✅ Step 4 – Install AMA Syslog Connector on Syslog VM

1. In the Azure Portal, go to **Microsoft Sentinel → Settings → Data Connectors**
2. Select **Syslog (Linux)** and click **Open connector page**
3. Follow the steps to:
   - Install the **Azure Monitor Agent (AMA)** on the `syslog-vm`
   - Configure the **Data Collection Rule (DCR)** to forward syslog messages
   - Enable collection for `Syslog` with relevant facilities and severities (e.g. `auth`, `user`, etc.)

> Make sure the VM is associated with the DCR and connected to the right workspace.

---

## ✅ Step 5 – Verify Logs in Log Analytics

1. Go to **Microsoft Sentinel → Logs**
2. Run the following query:

```kql
Syslog
| where HostName contains "syslog-vm"
| sort by TimeGenerated desc
```

3. **Refresh the NGINX website** again and verify new entries are appearing in near real-time.

---

## ✅ Step 6 – Create KQL Parser Using Copilot

1. In the **Logs** blade, copy a sample syslog message.
2. Click the **Copilot** tab and paste the message.
3. Ask Copilot:  
   _"Write a KQL query to parse this message into structured columns like timestamp, source IP, request, status, user agent, etc."_

4. **Run and iterate** on the suggested KQL until you have your desired output.

5. Save the final KQL as a **KQL function** in Sentinel for reuse.

---

## ✅ Step 7 – Create Analytics Rule for External Access

1. In Sentinel → **Analytics → Create new rule**
2. Select **Custom query rule**
3. Use your parser function (e.g. `NGINXParsedLogs()`) and write a KQL query like:

```kql
NGINXParsedLogs
| where SourceIP != "<your-client-public-ip>"
| where RequestUri contains "/"
```

4. Set alert frequency, threshold, and actions (email, Logic App, etc.)

---

## 🎉 You're Done!

You now have a working demo of:

- NGINX sending logs to a syslog VM
- Syslog collected via AMA to Sentinel
- Live parsing and alerting via KQL + Copilot

---

## 🧹 Cleanup (Optional)

```bash
azd down --template demo-deploy
azd down --template mtt-deploy
```

---

*Author: Your Name*  
*Date: 2025-07-04*
