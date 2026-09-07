# **Dataset**

**This directory documents the dataset used by the horse racing business analytics project.**

**The original raw dataset is not included in this repository.**

---

## **Dataset Overview**

**The project uses a historical horse racing outcomes dataset covering UK and Ireland racing from 2005 to 2019.**

**The original dataset contains:**

- **744K+ rows**
- **42 columns**
- **Numerical and categorical variables**
- **Race-level information**
- **Horse-level information**
- **Jockey and trainer information**
- **Historical performance indicators**

**The dataset was used to investigate and model horse finishing position.**

---

## **Expected File**

**The R analysis expects the dataset to be available locally as:**

**`all_races05_19.csv`**

**The file should be placed in the project root directory:**


horse-race-business-analytics/
│
├── horse_race_business_analytics.R
├── all_races05_19.csv
└── ...

---

## **Data Fields**

**The analysis works with variables representing different aspects of horse racing, including:**

### **Race Information**

- **Race ID**
- **Course**
- **Race distance**
- **Going**
- **Race group**
- **Race type**
- **Number of runners**

### **Horse Information**

- **Horse name**
- **Age**
- **Weight**
- **Sire**
- **Dam**

### **Performance Information**

- **Official Rating (`or`)**
- **Top Speed (`ts`)**
- **Racing Post Rating (`rpr`)**
- **Expected chance**
- **Finishing position (`pos`)**

### **Time Information**

- **Month**
- **Year**
- **Finishing time**
- **Finishing minutes**
- **Finishing seconds**

---

## **Data Preparation**

**Before modelling, the R workflow performs several transformations.**

**These include:**

- **Cleaning the finishing-position field**
- **Handling missing values**
- **Forward-filling missing finishing-time values**
- **Extracting minute and second components**
- **Removing unnecessary variables**
- **Removing incomplete records from the selected modelling fields**
- **Frequency encoding categorical variables**
- **Winsorising numerical variables**
- **Scaling numerical variables**
- **Computing correlation matrices**
- **Removing the highly correlated `prob` variable**
- **Creating training and test datasets**

**The final target variable used for prediction is:**

**`pos`**

**This represents the finishing position of the horse.**

---

## **Exploratory Analysis**

**The dataset is also used for exploratory analysis covering areas such as:**

- **Number of wins by horse**
- **Position across race distances**
- **Weight across age groups of winning horses**
- **Frequently occurring jockeys**
- **Frequently occurring trainers**
- **Sire-level analysis**
- **Correlation between numerical variables**

---

## **Data Source**

**The original project used a publicly available Kaggle horse racing dataset covering UK racing results.**

**The raw dataset is intentionally excluded from this repository.**

**Users should obtain the data independently and comply with the original dataset's terms of use.**

---

## **Reproducibility**

**To reproduce the analysis:**

1. **Obtain the original dataset.**
2. **Save it as `all_races05_19.csv`.**
3. **Place it in the project root directory.**
4. **Install the packages listed in `requirements.md`.**
5. **Open `horse_race_business_analytics.R`.**
6. **Run the script in R/RStudio.**
