## COSMOSMON - monitoring COSMOS node using Node Exporter, Prometheus and Grafana.  

Both exporter and the template (Prometheus/Grafana) are public and they demonstrate a possibility to display basic metrics of COSMOS network. It’s also planned to expand the number of chain specific metrics, so that we can have a detailed and complete picture of ecosystem. In this regard, public contribution is welcomed!  


### Requirements:  
1. Node exporter
2. Prometheus
3. Grafana  

### Start Node Exporter with collector.textfile.directory.  

Create node_exporter user:  
```  
sudo useradd --no-create-home --shell /bin/false node_exporter  
```  

Create directory:  
```
sudo mkdir -p /var/lib/node_exporter/textfile_collector
  
sudo chown node_exporter:node_exporter /var/lib/node_exporter/textfile_collector  
``` 
Create cosmos_metrics.prom   
```  
sudo touch /var/lib/node_exporter/textfile_collector/cosmos_metrics.prom  
sudo chmod o+w /var/lib/node_exporter/textfile_collector/cosmos_metrics.prom  
```  
Create service file:  
```
vim /etc/systemd/system/node_exporter.service  
[Unit]  
Description=Node Exporter  
Wants=network-online.target  
After=network-online.target  
  
[Service]  
User=node_exporter  
Group=node_exporter  
Type=simple  
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory /var/lib/node_exporter/textfile_collector  
  
[Install]  
WantedBy=multi-user.target  
```  
### Start script cosmos_exporter.sh.  
This script collect metrics to text file. You need to set variables in cosmos_exporter.sh. For example you can use supervisor to start this script.   
To check Node Exporter use curl http://localhost:9100/metrics.  
### Import template to Grafana.  
You can import template cosmos_dashboard.json to Grafana using standard import procedure.  

