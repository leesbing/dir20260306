# logistic GLMM 模型运行代码

```python
from statsmodels.genmod.bayes_mixed_glm import BinomialBayesMixedGLM

print("\nRunning GLMM (logistic mixed model)")

# 构建数据列保存 响应变量 
long["is1"] = (long["response"] == 1).astype(int)

# 将 synthetic_id 列转换为分类变量
long["synthetic_id"] = long["synthetic_id"].astype("category")

# GLMM模型
model = BinomialBayesMixedGLM.from_formula(
    "is1 ~ group",
    {"synthetic_id": "0 + C(synthetic_id)"},
    long
)

result = model.fit_vb()

print("\nGLMM result")
print(result.summary())

# Odds ratio
# odds_ratio = np.exp(result.params)

print("\nGLMM Odds Ratios")
# print(odds_ratio)

fe = result.params[:2]

print("fixed effects: ", fe)
print("Odds ratios (fixed effects)")
print(np.exp(fe))
```

# 运行代码的分布解析

## 一、 构建数据列保存二分类的响应变量 
```python
long["is1"] = (long["response"] == 1).astype(int)
```
## 二、 指定随机效应所在的列
将 synthetic_id 列转换为分类变量，方便 logistic GLMM 模型为每个 synthetic_id 都设立一个独立的随机效应。
```python
long["synthetic_id"] = long["synthetic_id"].astype("category")
```

## 三、设置使用 logistic GLMM 模型的参数
```python
model = BinomialBayesMixedGLM.from_formula(
    "is1 ~ group",
    {"synthetic_id": "0 + C(synthetic_id)"},
    long
)
```

### 1️⃣ 整体结构含义

```python
model = BinomialBayesMixedGLM.from_formula(
    "is1 ~ group",
    {"synthetic_id": "0 + C(synthetic_id)"},
    long
)
```

使用 logistic GLMM 模型 `BinomialBayesMixedGLM.from_formula` 的参数有三部分：

| 部分                                        | 含义                  |
| ----------------------------------------- | ------------------- |
| `"is1 ~ group"`                           | 固定效应（fixed effects） |
| `{"synthetic_id": "0 + C(synthetic_id)"}` | 随机效应结构              |
| `long`                                    | 数据                  |

模型对应的数学公式是：

$$
\text{logit}(P(is1_{ij}=1)) =
\beta_0 + \beta_1 group_{ij} + u_j
$$

其中

* $u_j$ = **synthetic_id 的随机效应**

---

### 2️⃣ 为什么要写成字典 `{}`

`BinomialBayesMixedGLM` 要求：

```python
{random_effect_name : random_effect_formula}
```

这里：

```python
{"synthetic_id": "0 + C(synthetic_id)"}
```

意思是：

> 为 **synthetic_id** 创建一组随机效应。

---

### 3️⃣ `"0 + C(synthetic_id)"` 的含义

这个公式使用 `Patsy` 语法。

#### `C(synthetic_id)` 的含义

```
C()
```

表示：

> 把 `synthetic_id` 当作 **categorical variable**

例如：

| synthetic_id |
| ------------ |
| A            |
| B            |
| C            |

会变成设计矩阵：

| C(A) | C(B) | C(C) |
| ---- | ---- | ---- |
| 1    | 0    | 0    |
| 0    | 1    | 0    |
| 0    | 0    | 1    |

---

#### `0 +` 的含义

```
0 +
```

表示：

> **不要 intercept**

如果不写 `0 +`，默认会有：

```
intercept + C(synthetic_id)
```

这样就会产生 **共线性问题**。

所以随机效应设计矩阵通常写：

```
0 + C(group)
```

---

### 4️⃣ 实际含义（最重要）

```python
"0 + C(synthetic_id)"
```

表示：

> **每个 synthetic_id 都有一个随机截距**

也就是：

$$
u_j \sim N(0, \sigma^2)
$$

其中：

* $j$ = synthetic_id

---

### 5️⃣ 对应 lme4 语法

如果用R的 lme4 包

R 语言写法是：

```R
glmer(is1 ~ group + (1 | synthetic_id), family=binomial)
```

对应关系：

| R (lme4) | Python statsmodels |                         |
| -------- | ------------------ | ----------------------- |
| `(1      | synthetic_id)`     | `"0 + C(synthetic_id)"` |

---

### 6️⃣ 随机效应结构图

你的模型结构是：

```
            group (fixed effect)
                   │
                   ▼
            logit(P(is1))
                   │
          ┌────────┴────────┐
          │                 │
     synthetic_id1     synthetic_id2 ...
      random effect      random effect
```

也就是：

```
trial (row)
   │
   ├── fixed effect: group
   └── random intercept: synthetic_id
```

---

### 7️⃣ 为什么需要这个随机效应

因为：

* 同一个 `synthetic_id` 的多个观测 **不是独立的**

随机效应允许：

```
不同 synthetic_id 有不同 baseline probability
```

例如：

| synthetic_id | baseline P(is1) |
| ------------ | --------------- |
| A            | 0.3             |
| B            | 0.5             |
| C            | 0.2             |

---

### 8️⃣ 如果不加随机效应

模型变成：

```
is1 ~ group
```

问题：

* 忽略 group 内相关性
* 标准误会偏小
* p-value 可能过于乐观

---

### 9️⃣ 随机效应总结**

```python
{"synthetic_id": "0 + C(synthetic_id)"}
```
是 **随机效应（random effects）的公式定义**。它告诉模型 **如何为某个分组变量建立随机效应设计矩阵**。

意思是：

> 为 **synthetic_id 建立随机截距(random intercept)**，
> 每个 synthetic_id 都有一个独立的随机效应。

等价于 R：

```
(1 | synthetic_id)
```

---

### 🔟 补充：有些情况下，不仅考虑 participant 还要考虑 item 随机效应

在 **心理学、语言学、行为实验的 GLMM** 中 item 随机效应非常关键，因为随机效应结构会直接影响 **标准误和 p 值是否可靠**。

通常遵循一个经典原则（来自语言学统计界）：

> **如果实验同时抽样了 participant 和 item，就应该同时建两个随机效应。**

下面系统解释。

---

#### A、 只有 `(1|participant)` 的情况

模型：

```r
(1 | participant)
```

含义：

$$
\text{logit}(P(Y_{ij}=1)) = \beta_0 + \beta_1 X_{ij} + u_j
$$

其中：

* $u_j$ = participant 随机截距

表示：

> **不同 participant 有不同 baseline**

---

##### 适用场景

只有 **participant 被重复测量**，而 stimulus/item **不是随机样本**。 本次实验中，所有被试人都是回答同一个问题，所以不考虑 item 随机效应。


例如：

| participant | condition | response |
| ----------- | --------- | -------- |
| p01         | A         | 1        |
| p01         | B         | 0        |
| p02         | A         | 1        |
| p02         | B         | 1        |

特点：

* stimulus 固定
* participant 是随机抽样

例如：

* 每个被试做 **同一组任务**
* 没有 item variability

---

#### B、 `(1|participant) + (1|item)` 的情况

模型：

```r
(1 | participant) + (1 | item)
```

数学形式：

$$
\text{logit}(P(Y_{ij}=1)) =
\beta_0 + \beta_1 X_{ij} + u_j + v_i
$$

其中

* $u_j$：participant 随机效应
* $v_i$：item 随机效应

---

##### 含义

允许：

| 来源          | variability |
| ----------- | ----------- |
| participant | 不同人反应不同     |
| item        | 不同刺激难度不同    |

---

##### 典型实验

语言学/心理学实验：

| participant | item      | condition | response |
| ----------- | --------- | --------- | -------- |
| p01         | sentence1 | A         | 1        |
| p01         | sentence2 | B         | 0        |
| p02         | sentence1 | A         | 1        |
| p02         | sentence2 | B         | 1        |

这里：

* sentence 是 **随机抽样**
* participant 也是 **随机抽样**

因此需要：

```r
(1|participant) + (1|item)
```

---

#### C、 为什么必须加 item

如果不加 `(1|item)`：

模型会假设：

```text
所有 stimulus 难度完全一样
```

但现实：

| item      | difficulty |
| --------- | ---------- |
| sentence1 | easy       |
| sentence2 | hard       |
| sentence3 | medium     |

如果忽略 item variability：

结果会：

* **低估标准误**
* **p 值过小**
* **假阳性**

---

#### D、 经典论文结论

语言学统计领域有一篇非常著名的论文：

Barr et al. 2013 Random effects structure for confirmatory hypothesis testing

核心结论：

> **Maximal random effects structure should be used whenever possible**

也就是：

```r
(1 + slope | participant) + (1 + slope | item)
```

---

#### E、 一个直观例子

假设实验：

* 40 participants
* 40 sentences
* 每人看全部句子

数据：

| participant | item | condition | response |
| ----------- | ---- | --------- | -------- |

变异来源：

```
response variation
│
├── participant variability
└── item variability
```

正确模型：

```r
(1|participant) + (1|item)
```

---

#### F、 Python statsmodels 写法

在
statsmodels
中写：

```python
random = {
    "participant": "0 + C(participant)",
    "item": "0 + C(item)"
}
```

模型：

```python
model = BinomialBayesMixedGLM.from_formula(
    "response ~ condition",
    random,
    data
)
```

---

#### G、 三种常见实验结构

| 实验结构                           | 推荐随机效应        |                           |        |
| ------------------------------ | ------------- | ------------------------- | ------ |
| participant repeated measures  | `(1           | participant)`             |        |
| participant × item             | `(1           | participant)+(1           | item)` |
| participant × item + condition | `(1+condition | participant)+(1+condition | item)` |

---

#### H、 判断规则（最实用）

问自己两个问题：

##### Q1 participant 是否随机抽样？

如果是 → `(1|participant)`

---

##### Q2 item 是否随机抽样？

如果是 → `(1|item)`

---

最终：

```
两个都是随机抽样
↓
必须两个随机效应
```

---

#### ✅ 总结

| 模型  | 使用条件            |          |             |
| --- | --------------- | -------- | ----------- |
| `(1 | participant)`   | 只有被试重复测量 |             |
| `(1 | participant)+(1 | item)`   | 被试和刺激都是随机样本 |

心理学 / 语言学实验 **90% 都属于第二种**。

---

## 四、拟合模型

```python
result = model.fit_vb()
```

## 五、查看模型输出
```python
print("\nGLMM result")
print(result.summary())
```
得到模型输出如下：
```text
Running GLMM (logistic mixed model)

GLMM result
                  Binomial Mixed GLM Results
==============================================================
                Type Post. Mean Post. SD   SD  SD (LB) SD (UB)
--------------------------------------------------------------
Intercept          M     0.5800   0.0656                      
group[T.Group2]    M    -0.3339   0.0905                      
synthetic_id       V    -0.0916   0.0384 0.912   0.845   0.985
==============================================================
Parameter types are mean structure (M) and variance structure
(V)
Variance parameters are modeled as log standard deviations

GLMM Odds Ratios
fixed effects:  [ 0.58004189 -0.333921  ]
Odds ratios (fixed effects)
[1.78611325 0.71611036]
```

### GLMM模型核心结果解读

你得到的核心输出是：

```
Binomial Mixed GLM Results
==============================================================
                Type Post. Mean Post. SD
--------------------------------------------------------------
Intercept          M     0.5800
group[T.Group2]    M    -0.3339
participant        V    -0.0916
==============================================================
```

模型：

$$
\text{logit}(P(\text{response}=1)) = \beta_0 + \beta_1 \cdot group + u_{participant}
$$

其中

```
u_participant ~ N(0, σ²)
```

---

#### Group1 和 Group2 选择 1 的平均概率

##### 1. Group1 选择 1 的平均概率 (又称 baseline 概率) 

```
Intercept = 0.580
```

**对应的 baseline 概率**：  
由GLMM数学公式代入拟合得到的参数，计算group1选择 1 的概率，过程如下：
$$
\log(\frac{P}{1+P} )=  Intercept（也就是0.580） + group[T.Group2] * 0 （见注1）+ 0 (随机效应，见注2)
$$

* 注1：因为group1选择1的概率是baseline，所以这个乘数为0。如果计算group2选择1的概率，这个乘数就为1
* 注2：因为随机效应是均值为0的正态分布，对平均概率的影响为0。

由此得到：**group1选择1的概率的odd（比率）计算公式**
$$
\frac{P}{1-P} =  e^{Intercept} =odd_{g1} 
$$

其中，我们以 $ odd_{g1} $ 表示group1选择1的概率的odd (即即本公式中的  $\frac{P}{1-P} $)。

还可以得到：
$$
\log(\frac{P}{1-P} )=  Intercept =  0.580 
$$
转换后得到：
$$
P = \frac{e^{Intercept}}{1+e^{Intercept}} =\frac{e^{0.58}}{1+e^{0.58}}
$$

python计算代码：
```python
np.exp(0.58)/(1+np.exp(0.58))
```

得到结果：

```
p ≈ 0.641
```

解释：

```
Group1 选择 1 的平均概率 ≈ 64%
```

与你数据的整体比例（$0.63 = \frac{344}{344+23+179}$）非常接近。

✅ **一句话总结**

Group1 选择 1 的概率计算公式：

$$
P(Y=1|Group1)=\frac{e^{Intercept}}{1+e^{Intercept}}
$$

##### 2. Group2 选择 1 的平均概率  
```
Intercept = 0.580
group[T.Group2] = -0.3339
```
把上述拟合得到的参数代入GLMM数学公式，计算group2选择 1 的概率，过程如下：
$$
\log(\frac{P}{1+P} )=  Intercept + group[T.Group2] \times 1 （见注3）+ 0 (随机效应，见注4)
$$

* 注3：因为group2选择1的概率不是baseline，所以这个乘数为1。
* 注4：因为随机效应是均值为0的正态分布，对平均概率的影响为0。

由此得到：**group2选择1的概率的odd（比率）计算公式**
$$
\frac{P}{1-P} =  e^{Intercept + group[T.Group2]}  
$$
转换后得到：
$$
P = \frac{e^{Intercept + group[T.Group2]}  }{1+e^{-(Intercept + group[T.Group2])}} = \frac{e^{(0.58 -0.3339)}}{1+e^{(0.58 -0.3339)}} 
$$

python计算代码：
```python
np.exp(0.58-0.3339)/(1+np.exp(0.58-0.3339))
```

得到结果：

```
p ≈ 0.561
```

✅ **一句话总结**

Group2 选择 1 的概率计算公式：

$$
P(Y=1|Group2)=\frac{e^{Intercept+group[T.Group2]}}{1+e^{Intercept+group[T.Group2]}}
$$

---

#### 固定效应（最重要）

由GLMM数学公式代入拟合得到的参数，计算group2选择 1 的概率，过程如下：
$$
\log(\frac{P}{1-P} )=  Intercept + group[T.Group2] \times 1 （见注1）+ 0 (随机效应，见注2)
$$

* 注1：因为group2选择1的概率是不是baseline，所以这个乘数为1。如果计算group1选择1的概率，这个乘数就为0
* 注2：因为随机效应是均值为0的正态分布，所以这个数为0。

得到：
$$
 \log(\frac{P}{1-P} )=  Intercept + group[T.Group2] =  \log(odd_{g2} )
$$
其中，我们以 $ odd_{g2} $ 表示group2选择1的概率的odd（即本公式中的 $\frac{P}{1-P} $ ）。

从而得到 **group2选择1的概率的odd（比率）计算公式**
$$
odd_{g2} = \frac{P}{1-P} =  e^{Intercept} \times e^{group[T.Group2]}
$$

又因为前一节中已经得到 $ e^{Intercept} =  odd_{g1} $ ，所以
$$
odd_{g2}=  e^{Intercept + group[T.Group2]} = e^{Intercept} * e^{group[T.Group2]}= odd_{g1} \times e^{group[T.Group2]}
$$
转换后得到：
$$
\frac{odd_{g2}}{odd_{g1} } = e^{group[T.Group2]}
$$

再次转换，得到
$$
\log(\frac{odd_{g2}}{odd_{g1} } )= group[T.Group2]
$$
所以可以得出：group[T.Group2]项

```
coef = -0.3339
```

的含义：

```
Group2 相对于 Group1 的 log-odds 变化。
```
**注意：这里的 log-odds 是指 $ \log(\frac{odd_{g2}}{odd_{g1}} ) $**

计算 **Odds Ratio （即 $ \frac{odd_{g2}}{odd_{g1}}  $**）

$$
OR = \frac{odd_{g2}}{odd_{g1}} =  e^{group[T.Group2]} = e^{-0.3339}
$$

结果：

```
OR ≈ 0.716
```

解释：


$odd_{g2} = 0.716 × odd_{g1}$


也就是说：

**Group2 更不倾向选择 1。**

##### 转换成百分比变化

odds 的变化率：

$$
\text{change} = (OR-1) \times 100 \% = (0.716-1)\times 100\% =-0.284\times100\%
$$

所以

```text
Group2 的 odds 比 Group1 低 28.4%
```
##### 为什么不可以说 “概率降低 28%”

因为

> 这里的 OR 是 odds 的比例 $ \frac{odd_{g2}}{odd_{g1}} $  
> 不是 probability 的比例


实际概率：

| group  | probability |
| ------ | ----------- |
| Group1 | 0.641       |
| Group2 | 0.561       |

概率只下降：

```text
0.641 − 0.561 = 0.08
```

即 **8个百分点**。

---

##### 一句统计学总结

logistic GLMM 中：

```text
exp(β) = odds ratio
```

因此

```text
β1 = -0.3339
```

意味着

```text
Group2 odds 是 Group1 odds 的 0.716 倍
即降低约 28%
```
---

#### 随机效应

```
participant V = -0.0916
```

注意：

```
Variance parameters are modeled as log standard deviations
```

所以：

```math
SD = e^{-0.0916}
```

结果：

```
SD ≈ 0.91
```

解释：

```
不同 participant 之间存在较大差异
```

也就是：

```
个体差异明显
```

---


#### 统计结论

综合 GLMM：

| 结果                  | 解释            |
| ------------------- | ------------- |
| Intercept OR=1.79   | Group1选择1概率较高 |
| Group2 OR=0.72      | Group2更少选择1   |
| participant SD≈0.91 | 个体差异明显        |

---

## 六、GLMM统计检验
见《GLMM检验两组数据概率的差异_v1.ipynb》对应章节