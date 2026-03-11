# Azure Log Analytics - KQL Queries for NetworkBuster
# Kusto Query Language (KQL) queries for monitoring, analytics, and AI training data collection

## 🔍 Visitor Tracking Queries

### 1. Distinct Visitor IPs (Last 30 Days)
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| distinct ClientIP
```

**Purpose:** Extract unique visitor IP addresses for geographic analysis and visitor tracking
**Output:** List of distinct ClientIP values
**Use Case:** Visitor behavior model training data

---

### 2. Visitor Count by IP (Detailed)
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    VisitCount = count(),
    FirstVisit = min(TimeGenerated),
    LastVisit = max(TimeGenerated),
    AvgResponseTime = avg(DurationMs),
    UniquePages = dcount(Path)
    by ClientIP
| sort by VisitCount desc
```

**Purpose:** Analyze visitor patterns and engagement metrics
**Output:** IP, visit count, timing, performance, page diversity
**Use Case:** Visitor behavior scoring for recommendations

---

### 3. Top Pages by Traffic
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| where HttpStatus == 200
| summarize 
    PageViews = count(),
    UniqueVisitors = dcount(ClientIP),
    AvgResponseTime = avg(DurationMs)
    by Path
| sort by PageViews desc
```

**Purpose:** Identify most popular content pages
**Output:** Page path, view count, visitor count, performance
**Use Case:** Content recommender model training

---

### 4. Visitor Session Analysis
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    SessionCount = count(),
    TotalDuration = sum(DurationMs),
    AvgSessionDuration = avg(DurationMs),
    RequestsPerSession = count() / dcount(ClientIP)
    by ClientIP, bin(TimeGenerated, 1h)
| sort by AvgSessionDuration desc
```

**Purpose:** Analyze user session patterns and engagement
**Output:** IP, session metrics per hour
**Use Case:** User engagement analysis

---

## 📊 Performance Monitoring Queries

### 5. Response Time Analysis
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(7d)
| summarize 
    Requests = count(),
    AvgResponseTime = avg(DurationMs),
    P50ResponseTime = percentile(DurationMs, 50),
    P95ResponseTime = percentile(DurationMs, 95),
    P99ResponseTime = percentile(DurationMs, 99),
    MaxResponseTime = max(DurationMs)
    by Path
| sort by AvgResponseTime desc
```

**Purpose:** Monitor API/page performance and identify bottlenecks
**Output:** Response time percentiles by endpoint
**Use Case:** Performance optimizer model training

---

### 6. Error Rate Tracking
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    TotalRequests = count(),
    ErrorCount = countif(HttpStatus >= 400),
    ErrorRate = (countif(HttpStatus >= 400) * 100.0 / count()),
    by HttpStatus, Path
| where ErrorRate > 0
| sort by ErrorCount desc
```

**Purpose:** Track application errors and performance issues
**Output:** Status code, path, error count, error rate
**Use Case:** System health monitoring

---

### 7. Throughput Analysis (Requests Per Second)
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(24h)
| summarize 
    RequestCount = count(),
    UniqueIPs = dcount(ClientIP),
    AvgResponseTime = avg(DurationMs)
    by bin(TimeGenerated, 5m)
| extend RPS = RequestCount / 300  // 300 seconds = 5 minutes
| sort by TimeGenerated desc
```

**Purpose:** Monitor system throughput and load patterns
**Output:** Time bucket, request count, RPS, unique visitors
**Use Case:** Auto-scaling decisions

---

## 🌍 Geographic & Device Analysis

### 8. Traffic by Country (using GeoIP)
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    Requests = count(),
    UniqueVisitors = dcount(ClientIP),
    AvgResponseTime = avg(DurationMs)
    by ClientIP, GeoCountry
| sort by Requests desc
```

**Purpose:** Analyze visitor geographic distribution
**Output:** Country, request count, visitor count, performance
**Use Case:** Localization and CDN optimization

---

### 9. Device Type Distribution
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    Requests = count(),
    AvgResponseTime = avg(DurationMs),
    ErrorRate = (countif(HttpStatus >= 400) * 100.0 / count())
    by UserAgent
| sort by Requests desc
```

**Purpose:** Understand device/browser breakdown
**Output:** User agent, request count, performance, error rate
**Use Case:** UI/UX optimization

---

## 🎯 Content Recommendation Queries

### 10. User Content Interaction Patterns
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| where HttpMethod == "GET"
| summarize 
    ViewCount = count(),
    UniqueUsers = dcount(ClientIP),
    AvgTimeOnPage = avg(DurationMs),
    LastViewed = max(TimeGenerated)
    by Path
| project 
    ContentID = Path,
    PopularityScore = ViewCount,
    EngagementScore = (ViewCount * AvgTimeOnPage / 1000),
    UserCount = UniqueUsers,
    LastViewed
| sort by PopularityScore desc
```

**Purpose:** Generate content interaction data for recommendation engine
**Output:** Content ID, popularity score, engagement, user count
**Use Case:** Content recommender model features

---

### 11. Click-Through Patterns
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| where HttpStatus == 200
| summarize 
    Clicks = count(),
    ClickRate = (count() * 100.0 / dcount(ClientIP))
    by ClientIP, Path
| sort by Clicks desc
```

**Purpose:** Track which content gets clicked by which users
**Output:** User IP, path, click count, click rate
**Use Case:** Personalization features

---

## ♻️ Sustainability & Resource Metrics

### 12. Server Resource Utilization
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(7d)
| summarize 
    RequestCount = count(),
    AvgCPU = avg(CpuPercent),
    AvgMemory = avg(MemoryPercent),
    MaxCPU = max(CpuPercent),
    MaxMemory = max(MemoryPercent)
    by bin(TimeGenerated, 1h)
| sort by TimeGenerated desc
```

**Purpose:** Monitor resource consumption for sustainability
**Output:** Time bucket, request count, CPU/memory metrics
**Use Case:** Sustainability predictor model, cost optimization

---

### 13. Energy Efficiency Score
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(24h)
| extend 
    Efficiency = RequestCount / (CpuPercent + MemoryPercent + 0.1)
| summarize 
    AvgEfficiency = avg(Efficiency),
    PeakLoad = max(RequestCount),
    ResourceUtilization = avg(CpuPercent + MemoryPercent)
    by bin(TimeGenerated, 1h)
| sort by AvgEfficiency desc
```

**Purpose:** Calculate energy efficiency metrics
**Output:** Efficiency score, peak load, resource utilization
**Use Case:** Green computing metrics

---

## 🔔 Alert & Anomaly Detection Queries

### 14. Spike Detection (Unusual Traffic)
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(7d)
| summarize 
    RequestCount = count(),
    AvgResponseTime = avg(DurationMs)
    by bin(TimeGenerated, 5m)
| extend 
    BaselineCount = 1000,  // Set your baseline
    Deviation = (RequestCount - BaselineCount) / BaselineCount * 100
| where abs(Deviation) > 50  // Alert if >50% deviation
| sort by TimeGenerated desc
```

**Purpose:** Detect unusual traffic spikes or dips
**Output:** Time, request count, deviation percentage
**Use Case:** Anomaly detection and alerting

---

### 15. Performance Degradation Detection
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(7d)
| summarize 
    AvgResponseTime = avg(DurationMs),
    P95ResponseTime = percentile(DurationMs, 95)
    by bin(TimeGenerated, 1h)
| extend 
    BaselineP95 = 500,  // Set your baseline
    Degradation = (P95ResponseTime - BaselineP95) / BaselineP95 * 100
| where P95ResponseTime > BaselineP95 * 1.2  // Alert if 20% slower
| sort by TimeGenerated desc
```

**Purpose:** Alert when performance degrades
**Output:** Time, response times, degradation percentage
**Use Case:** Performance monitoring

---

### 16. Error Rate Spike
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(7d)
| summarize 
    TotalRequests = count(),
    ErrorCount = countif(HttpStatus >= 400),
    ErrorRate = (countif(HttpStatus >= 400) * 100.0 / count())
    by bin(TimeGenerated, 5m)
| where ErrorRate > 5  // Alert if error rate > 5%
| sort by TimeGenerated desc
```

**Purpose:** Alert on elevated error rates
**Output:** Time, error count, error rate percentage
**Use Case:** Service health monitoring

---

## 📈 Trend Analysis Queries

### 17. Weekly Visitor Trend
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    UniqueVisitors = dcount(ClientIP),
    TotalRequests = count(),
    AvgResponseTime = avg(DurationMs)
    by bin(TimeGenerated, 1d)
| sort by TimeGenerated desc
| extend DayOfWeek = dayofweek(TimeGenerated)
```

**Purpose:** Track daily/weekly visitor trends
**Output:** Date, unique visitors, request count, performance
**Use Case:** Trend analysis, capacity planning

---

### 18. Monthly Visitor Growth
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(90d)
| summarize 
    MonthlyVisitors = dcount(ClientIP),
    MonthlyRequests = count()
    by bin(TimeGenerated, 30d)
| sort by TimeGenerated desc
| extend MoMGrowth = (MonthlyVisitors - prev(MonthlyVisitors)) / prev(MonthlyVisitors) * 100
```

**Purpose:** Track month-over-month growth
**Output:** Month, visitor count, growth percentage
**Use Case:** Business metrics, forecasting

---

## 🤖 AI Model Training Data Exports

### 19. Export for Visitor Behavior Model
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| summarize 
    session_duration = max(DurationMs),
    page_views = count(),
    avg_response_time = avg(DurationMs),
    error_count = countif(HttpStatus >= 400),
    unique_pages = dcount(Path),
    device_type = any(UserAgent)
    by ClientIP, bin(TimeGenerated, 1h)
| project 
    user_id = ClientIP,
    session_duration,
    page_views,
    avg_response_time,
    error_rate = (error_count / page_views * 100),
    unique_pages,
    device_type,
    timestamp = TimeGenerated
```

**Output Format:** CSV for Python training script
**Use Case:** Feature engineering for ML models

---

### 20. Export for Performance Optimizer Model
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(7d)
| summarize 
    response_time_ms = avg(DurationMs),
    throughput_rps = (count() / (max(TimeGenerated) - min(TimeGenerated)).TotalSeconds),
    error_rate = (countif(HttpStatus >= 400) * 100.0 / count()),
    cpu_percent = avg(CpuPercent),
    memory_percent = avg(MemoryPercent)
    by Path, bin(TimeGenerated, 5m)
| sort by TimeGenerated desc
```

**Output Format:** Time-series data
**Use Case:** Performance prediction model training

---

## 🔧 Operational Queries

### 21. Service Health Summary
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(24h)
| summarize 
    TotalRequests = count(),
    SuccessfulRequests = countif(HttpStatus < 400),
    FailedRequests = countif(HttpStatus >= 400),
    AvgResponseTime = avg(DurationMs),
    UniqueVisitors = dcount(ClientIP)
| extend SuccessRate = (SuccessfulRequests * 100.0 / TotalRequests)
```

**Purpose:** Quick health check dashboard
**Output:** Service metrics summary
**Use Case:** Monitoring dashboard

---

### 22. Container App Resource Summary
```kusto
ContainerAppConsoleLogs
| where TimeGenerated > ago(1h)
| summarize 
    AvgCPU = avg(CpuPercent),
    AvgMemory = avg(MemoryPercent),
    MaxCPU = max(CpuPercent),
    MaxMemory = max(MemoryPercent),
    TotalRequests = count()
| extend ResourceHealth = case(
    (AvgCPU < 50 and AvgMemory < 50), "Healthy",
    (AvgCPU < 75 and AvgMemory < 75), "Good",
    (AvgCPU < 90 and AvgMemory < 90), "Warning",
    "Critical"
)
```

**Purpose:** Current resource status
**Output:** CPU/memory metrics, health status
**Use Case:** Auto-scaling decisions

---

## 📋 Integration Guide

### Use with Python AI Training Pipeline
```python
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient

client = LogsQueryClient(credential=DefaultAzureCredential())

query = """
ContainerAppConsoleLogs
| where TimeGenerated > ago(30d)
| distinct ClientIP
"""

result = client.query_workspace(workspace_id, query)
```

### Export to CSV for Training
```powershell
# Use Azure CLI to export KQL results
az monitor log-analytics query \
  --workspace "workspace-id" \
  --analytics-query 'ContainerAppConsoleLogs | where TimeGenerated > ago(30d) | distinct ClientIP' \
  --out csv > visitor-ips.csv
```

---

## 🎯 Query Performance Tips

1. **Always use time filters:** `where TimeGenerated > ago(Xd)`
2. **Use bin() for aggregation:** `by bin(TimeGenerated, 1h)`
3. **Limit result set:** Add `| limit 1000` if needed
4. **Use distinct sparingly:** Can be performance-heavy
5. **Materialize large intermediate sets:** Use let statements
6. **Test with smaller time ranges first**

---

## 📊 Log Analytics Workspace Setup

**Required:**
- Log Analytics Workspace created in Azure
- Container Apps configured to send logs
- Appropriate RBAC permissions
- Retention policy set (30+ days recommended)

**Cost Optimization:**
- Set retention to 30 days for training data
- Use logs-only pricing model
- Archive old data to blob storage

---

**Status:** ✅ **READY FOR DEPLOYMENT**
**Version:** 1.0
**Last Updated:** December 14, 2025
