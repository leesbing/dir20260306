# 如何解释随机效应数值

例如：

```
participant A: 0.27
```

表示：

如果平均 log-odds 是：

```
0.58
```

该 participant 的 baseline：

```
0.58 + 0.27 = 0.85
```

说明：

```text
这个 participant 更倾向于选择1
```


# 为什么 `一个participant 的 baseline =0.85` 说明这个 participant 更倾向于选择1？

关键在于 **GLMM 中的“baseline”是在 log-odds（logit）尺度上**。
log-odds 越大，对应的 **选择1的概率就越高**。下面一步一步解释。

---

## 一、GLMM 的模型结构

你的模型：

\text{logit}(P(Y=1)) = \beta_0 + \beta_1 \cdot \text{Group2} + u_i

其中

* ( \beta_0 = 0.58 )（总体 baseline）
* ( u_i ) = participant 的随机截距

例如某 participant：

```text
u_i = 0.27
```

那么这个 participant 的 baseline logit 就是：

```text
0.58 + 0.27 = 0.85
```

---

## 二、为什么 logit 大意味着更倾向选择1

logit 的定义是：

[
\text{logit}(p) = \ln\left(\frac{p}{1-p}\right)
]

其中

[
\frac{p}{1-p}
]

是 **odds（成功与失败的比值）**。

因此：

```text
logit 越大
→ odds 越大
→ 选择1概率越高
```

---

## 三、把 baseline = 0.85 转换成概率

先算 odds：

[
odds = e^{0.85}
]

[
odds ≈ 2.34
]

再转概率：

[
p = \frac{odds}{1+odds}
]

[
p = \frac{2.34}{1+2.34}
]

[
p ≈ 0.70
]

所以：

```text
该 participant 选择1概率 ≈ 70%
```

---

## 四、与平均 participant 比较

平均 baseline：

```text
logit = 0.58
```

概率：

[
p = \frac{e^{0.58}}{1+e^{0.58}}
]

[
p ≈ 0.64
]

所以：

| participant   | logit | probability |
| ------------- | ----- | ----------- |
| average       | 0.58  | 0.64        |
| 该 participant | 0.85  | 0.70        |

可以看到：

```text
70% > 64%
```

因此：

```text
该 participant 更倾向选择1
```

---

## 五、直觉理解（非常重要）

随机效应 (u_i) 表示：

```text
participant 的个人偏好
```

如果

| u_i | 含义             |
| --- | -------------- |
| >0  | 更容易选1          |
| =0  | 平均 participant |
| <0  | 更容易选0          |

例如：

| participant | u_i   | logit | P(1) |
| ----------- | ----- | ----- | ---- |
| A           | +0.27 | 0.85  | 0.70 |
| B           | 0     | 0.58  | 0.64 |
| C           | -0.40 | 0.18  | 0.54 |

所以：

```text
随机截距越大
→ 选择1概率越高
```

---

## 六、为什么 GLMM 要这样建模

因为不同 participant 有 **系统性偏好**：

```text
有人更容易选1
有人更容易选0
```

随机截距 (u_i) 就是在建模这种 **participant variability**。

---

✅ **一句话总结**

```text
baseline = 0.85
意味着 log-odds 更高
→ odds 更大
→ probability 更高
→ 更倾向选择1
```

---

