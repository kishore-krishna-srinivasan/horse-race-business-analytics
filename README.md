# 🏇 Horse Race Business Analytics

**A practical business analytics project analysing historical UK and Ireland horse racing data using R, exploratory data analysis, statistical analysis and comparative machine learning.**

**The project investigates factors associated with race outcomes and evaluates multiple regression approaches for predicting finishing position.**

> **MSc Practical Business Analytics — University of Surrey**

---

## 📌 Overview

**Horse racing data contains a mixture of numerical, categorical and historical performance information, making it a useful case study for applied business analytics and predictive modelling.**

**This project uses a large historical dataset covering UK and Ireland horse racing results from 2005 to 2019. The analysis combines data cleaning, exploratory analysis, feature engineering, statistical investigation and machine learning to examine relationships within race data and compare predictive approaches.**

**The main objective was to develop and evaluate models capable of predicting horse finishing position while understanding the characteristics and limitations of different modelling approaches.**

---

## 📊 Dataset

**The original dataset contains:**

- **744K+ rows**
- **42 columns**
- **UK and Ireland racing data**
- **Coverage from 2005 to 2019**
- **Numerical and categorical variables**
- **Race, horse, jockey, trainer and performance-related information**

**Examples of variables used in the analysis include:**

- **Race ID**
- **Course**
- **Race distance**
- **Going**
- **Race group**
- **Race type**
- **Number of runners**
- **Horse name**
- **Trainer**
- **Jockey**
- **Age**
- **Weight**
- **Official Rating**
- **Top Speed**
- **Racing Post Rating**
- **Sire**
- **Dam**
- **Expected chance**
- **Finishing position**

**The raw dataset is not included in this repository.**

---

## 🎯 Business Analytics Objective

**The project explores how historical race information can be transformed into analytical insights and predictive models.**

**The main objectives were to:**

1. **Clean and prepare a large real-world dataset.**
2. **Explore relationships between race characteristics and finishing position.**
3. **Transform categorical and numerical variables into modelling-ready representations.**
4. **Compare different statistical and machine learning approaches.**
5. **Evaluate models using consistent performance metrics.**
6. **Analyse model behaviour and identify useful predictive factors.**
7. **Use the results to understand the strengths and limitations of different approaches.**

---

## 🔄 Analytical Workflow

```text
Raw Racing Data
       │
       ▼
Data Cleaning
       │
       ▼
Missing Value Handling
       │
       ▼
Data Transformation
       │
       ▼
Exploratory Data Analysis
       │
       ▼
Feature Engineering
       │
       ▼
Categorical Encoding
       │
       ▼
Outlier Treatment & Scaling
       │
       ▼
Correlation Analysis
       │
       ▼
Training / Test Split
       │
       ▼
10 Predictive Models
       │
       ▼
RMSE / MAE / R² Evaluation
       │
       ▼
Model Comparison & Interpretation

## 🧹 **Data Cleaning**

**The R workflow begins by loading and inspecting the original CSV dataset.**

**The dataset is checked for:**

- **Dimensions**
- **Data structure**
- **Missing values**
- **Data types**
- **Non-numeric values**
- **Relevant modelling variables**

### **Position Cleaning**

**The `pos` column contains position values that may include non-numeric characters.**

**These values are cleaned by removing non-numeric characters and converting the resulting values into numeric form.**

### **Missing Value Handling**

**Missing values in important numerical variables are handled using statistical imputation.**

**The following variables are processed:**

- **`or` — Official Rating**
- **`ts` — Top Speed**
- **`rpr` — Racing Post Rating**

**Mean-based imputation is applied to these fields.**

### **Finishing-Time Processing**

**Missing finishing-time information is forward-filled before converting the time values into a usable time representation.**

**The finishing time is then separated into:**

- **Finishing minutes**
- **Finishing seconds**

### **Removing Unnecessary Variables**

**Variables that are not required for the analytical and modelling workflow are removed.**

**The selected dataset retains the fields required for exploratory analysis, feature processing and predictive modelling.**

### **Final Data Selection**

**The analysis retains variables including:**

- **`race_ID`**
- **`course`**
- **`dist.f.`**
- **`going`**
- **`race_group`**
- **`race_type`**
- **`Runners`**
- **`horse_name`**
- **`trainer`**
- **`jockey`**
- **`pos`**
- **`dec`**
- **`age`**
- **`lbs`**
- **`or`**
- **`ts`**
- **`rpr`**
- **`sire`**
- **`dam`**
- **`prob`**
- **`Month`**
- **`Year`**
- **`fin_minutes`**
- **`fin_seconds`**
- **`exp_chance`**

**Rows with missing values in the selected fields are removed using `na.omit()`.**

---

## 🔎 **Exploratory Data Analysis**

**Exploratory Data Analysis was performed to understand patterns and relationships within the racing dataset before model development.**

**The analysis includes:**

### **🏆 Number of Wins by Horse**

**The number of races won by each horse is calculated by filtering records where `pos == 1`.**

**The results are grouped by horse and summarised to examine winning frequency.**

### **🏁 Position Distribution Across Race Distances**

**Box plots are used to examine the distribution of finishing positions across different race distances.**

### **⚖️ Weight Across Age Groups**

**The analysis examines the weight distribution of winning horses across different age groups.**

### **🏇 Jockey Analysis**

**The dataset is explored to identify frequently occurring jockeys.**

### **👤 Trainer Analysis**

**Trainer participation and frequency are examined to understand representation within the dataset.**

### **🐎 Sire Analysis**

**The most frequently occurring sires are identified, followed by analysis of Racing Post Rating across these groups.**

### **📈 Correlation Analysis**

**Correlation matrices are calculated to investigate relationships between numerical and encoded variables.**

---

## 🛠️ **Feature Engineering**

**Feature engineering transforms the cleaned dataset into a representation suitable for statistical and machine learning models.**

### **Categorical Features**

**The following variables are treated as categorical:**

- **`race_ID`**
- **`course`**
- **`going`**
- **`race_group`**
- **`race_type`**
- **`horse_name`**
- **`trainer`**
- **`jockey`**
- **`sire`**
- **`dam`**

### **Numerical Features**

**The following variables are treated as numerical:**

- **`dist.f.`**
- **`Runners`**
- **`age`**
- **`lbs`**
- **`or`**
- **`ts`**
- **`rpr`**
- **`prob`**
- **`pos`**
- **`dec`**
- **`Month`**
- **`Year`**
- **`fin_minutes`**
- **`fin_seconds`**
- **`exp_chance`**

### **🔢 Frequency Encoding**

**Categorical variables are transformed using frequency-based encoding.**

**Each categorical field is converted into a numerical representation based on the frequency of its observed categories.**

### **📉 Winsorisation**

**A winsorisation procedure is applied to numerical variables to reduce the influence of extreme values.**

**The analysis uses the 5th and 95th percentiles as the winsorisation boundaries.**

### **📏 Feature Scaling**

**The processed numerical variables are scaled before being used by the modelling approaches.**

### **🔗 Correlation Analysis and Feature Reduction**

**A correlation matrix is calculated after the initial feature processing.**

**The correlation analysis is used to investigate relationships between the processed variables and identify highly correlated fields.**

**The `prob` variable is removed because of its high correlation with `exp_chance`.**

**A second correlation matrix is then generated after removing the `prob` variable.**

---

## 🧪 **Training and Test Data**

**The processed dataset is divided into training and test data for model development and evaluation.**

**The workflow uses:**

- **70% training data**
- **30% test data**

**The target variable used for prediction is `pos`.**

**The `pos` variable represents the finishing position of the horse in the race.**

---

## 🤖 **Machine Learning**

**I implemented and evaluated ten different regression approaches to compare their predictive performance.**

**The models include:**

1. **Light Gradient Boosting Machine — LightGBM**
2. **Ridge Regression**
3. **Gradient Boosting Regression**
4. **LASSO Regression**
5. **Support Vector Regression — SVR**
6. **Elastic Net Regression**
7. **Decision Tree Regression**
8. **XGBoost with Sequences**
9. **XGBoost**
10. **Random Forest Regression**

**The comparison covers linear models, regularised regression, tree-based models, ensemble methods, support vector regression and sequence-based modelling.**

---

## 📊 **Model Evaluation**

**The models are evaluated using three primary performance metrics:**

- **Root Mean Squared Error — RMSE**
- **Mean Absolute Error — MAE**
- **R²**

**Lower RMSE and MAE indicate lower prediction error, while a higher R² indicates that a greater proportion of the observed variance is explained by the model.**

### **Test-Set Results**

| **Model** | **RMSE** | **MAE** | **R²** |
|---|---:|---:|---:|
| **LightGBM** | **0.4026** | **0.2814** | **0.7637** |
| **Ridge Regression** | **0.6606** | **0.4363** | **0.3628** |
| **Gradient Boosting Regression** | **0.4364** | **0.1905** | **0.7219** |
| **LASSO Regression** | **0.6666** | **0.4444** | **0.3511** |
| **SVR** | **0.2917** | **0.2451** | **0.9668** |
| **Elastic Net** | **0.3849** | **0.3138** | **1.0000** |
| **Decision Tree** | **0.5253** | **0.3977** | **0.6035** |
| **XGBoost with Sequences** | **0.0310** | **0.0270** | **1.0000** |
| **XGBoost** | **0.4127** | **0.2992** | **0.7458** |
| **Random Forest** | **0.4609** | **0.3358** | **0.6898** |

**The reported results show substantial differences in predictive performance across the ten approaches.**

**SVR achieved an R² of approximately 0.967 with an RMSE of approximately 0.292 on the reported test data.**

**Elastic Net and XGBoost with Sequences both produced an R² of approximately 1.000 on the reported test data.**

**XGBoost with Sequences also produced the lowest reported RMSE and MAE values.**

**These exceptionally high R² values should be interpreted carefully and considered alongside the feature construction, data relationships and validation methodology rather than being treated as proof of real-world predictive performance.**

---

## 🔬 **Model Comparison**

**The project compares model behaviour across different modelling families rather than relying on a single algorithm.**

**The analysis considers differences between:**

- **Linear models**
- **Regularised regression models**
- **Tree-based models**
- **Ensemble models**
- **Support Vector Regression**
- **Sequence-based approaches**

**Actual-versus-predicted scatter plots are also used to visually examine model predictions against observed finishing positions.**

**The comparison demonstrates the importance of evaluating multiple approaches when working with complex structured datasets.**

---

## 💡 **Feature Importance**

**Feature importance is investigated for tree-based modelling approaches.**

**The analysis examines the contribution of racing-related variables such as:**

- **Horse characteristics**
- **Sire information**
- **Dam information**
- **Racing Post Rating**
- **Race characteristics**
- **Race-type variables**
- **Other encoded racing attributes**

**The Random Forest analysis identified variables including `dam`, `damsire` and `sire` among influential features.**

**Feature importance provides an additional analytical perspective beyond aggregate model-performance metrics.**

---

## 📌 **Key Takeaways**

**This project demonstrates how a large historical dataset can be transformed into a structured business analytics and machine learning workflow.**

**Key areas covered include:**

- **Large-scale data preparation**
- **Data cleaning**
- **Missing-value handling**
- **Categorical feature encoding**
- **Frequency encoding**
- **Outlier treatment through winsorisation**
- **Feature scaling**
- **Exploratory data analysis**
- **Correlation analysis**
- **Feature reduction**
- **Statistical modelling**
- **Comparative machine learning**
- **Cross-validation**
- **Hyperparameter tuning**
- **Model evaluation**
- **Feature-importance analysis**
- **Interpretation of model performance**

**The project also demonstrates why model evaluation should consider multiple metrics, validation behaviour and the underlying data rather than relying on a single performance score.**

---

## 🛠️ **Technology Stack**

### **Programming Language**

- **R**

### **Data Analysis**

- **dplyr**
- **tidyr**
- **zoo**
- **lubridate**
- **magrittr**

### **Visualisation**

- **ggplot2**
- **corrplot**
- **knitr**

### **Machine Learning**

- **caret**
- **e1071**
- **glmnet**
- **gbm**
- **xgboost**
- **lightgbm**
- **rpart**

### **Supporting Packages**

- **Metrics**
- **vtreat**
- **class**
- **keras**
- **tensorflow**
- **crayon**
- **tune**
- **hms**

---

## ▶️ **Running the Analysis**

### **1. Install R**

**Install R and an R development environment such as RStudio.**

### **2. Obtain the Dataset**

**The original racing dataset is not included in this repository.**

**Place the dataset in the project directory using the expected filename:**

**`all_races05_19.csv`**

### **3. Install the Required Packages**

**Refer to `requirements.md` for the package list.**

### **4. Run the Analysis**

**Open the following file in RStudio:**

**`horse_race_business_analytics.R`**

**Execute the script to perform the data cleaning, exploratory analysis, feature engineering, model training and model evaluation.**

---

## ⚠️ **Dataset and Coursework Note**

**The raw racing dataset is intentionally not included in this repository.**

**The original coursework report and coursework materials are also not included.**

**This repository focuses on the analytical implementation, code and technical documentation.**

---

## 🎓 **Academic Context**

**Developed as part of the MSc Practical Business Analytics coursework at the University of Surrey.**

**The project demonstrates the practical application of business analytics, statistical modelling, exploratory data analysis and machine learning to a large real-world dataset.**
