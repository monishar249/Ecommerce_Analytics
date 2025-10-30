# SellerPath: Journey Optimization & Tag Diagnostics

**Goal:** Improve seller enrollment rates by identifying opt-in funnel gaps using **impression/click tracking data**, **seller metadata**, and **file-based ingestion events**.

## 🚀 Project Flow / Approach

###  Data Ingestion & Preprocessing
- Load raw data with key columns:
 - Perform data cleaning:
- Handle missing values and inconsistent tagging fields (e.g., `optin_cta_tagged`, `impression_tag_valid`).
- Standardize categorical values across data sources.

### Funnel Drop-off Analysis
Define funnel stages:IMPRESSION->CLICKS->ENROLLED

**Key Analysis Dimensions:**
- **Platform:** App vs Web  
- **Category & Kind:** Small Business, Enterprise, etc.  
- **Manual File Ingestion:** `manual_file_ingested = Yes/No`

**Metrics:**
- Drop-off % between each stage  
- Identify weakest funnel stage per segment

### Tag Validation Check
Evaluate tagging accuracy and its impact on enrollment:
- Correlate poor enrollments with:
  - `optin_cta_tagged = No`
  - `impression_tag_valid = No`
- Identify tag combinations and segments with the highest failure rate.

###  Seller Behavior Insights
Derive behavioral patterns influencing enrollment:
- Relation between `seller_tenure_months` and conversion
- Effect of `risk_rating` on likelihood to enroll
- Popular `product_opted` across seller types and platforms

### Power BI Dashboard

**Dashboard Highlights:**
-  **Funnel View:** Impressions → Clicks → Enrolled  
-  **Daily Trends:** Track drop-offs in click/enroll rates  
-  **Interactive Filters:** platform, category, region, kind, campaign_id  
- **Tagging Alerts:** Flag invalid impression or CTA tags  

##  Key Outcomes
- Identified key drop-off points in the seller journey  
- Highlighted tagging gaps leading to low enrollment accuracy  
- Delivered actionable insights via an interactive Power BI dashboard  

## 🛠️ Tech Stack
- **Languages:** PowerBI, SQL  
- **Visualization:** Power BI  



