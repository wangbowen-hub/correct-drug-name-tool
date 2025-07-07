# AI药物名称纠正工具

基于AI的药物名称智能纠正工具，使用AI进行药物名称的自动校验和纠正。

## 安装依赖

创建conda环境

```bash
conda create -n correct-drug-env python=3.10
conda activate correct-drug-env
```

安装所需依赖：

```bash
pip install -r requirements.txt
```

## 配置设置

1. 创建 `.env` 文件，配置LLM API相关信息：

```env
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=your_api_base_url_here
```

2. 准备待处理的Excel文件，确保药物名称数据在第一列

## 使用方法

### 基本用法

处理当前目录下的所有Excel文件：

```bash
python main.py
```

### 指定目录处理

处理指定目录下的Excel文件：

```bash
python main.py --dir /path/to/your/files
```

### 开启思考模式

开启AI思考模式进行更详细的处理：

```bash
python main.py --thinking
```

### 组合使用

同时指定目录和开启思考模式：

```bash
python main.py --dir /path/to/your/files --thinking
```

## 输入文件格式

- 支持 `.xlsx` 格式的Excel文件
- 药物名称应位于第一列


## 输出结果

程序会为每个处理的Excel文件生成一个以 `correct-` 为前缀的新文件，包含以下列：

- **原始列**：原始药物名称数据
- **更正后**：AI纠正后的药物名称
- **是否更正**：标记该药物名称是否被修改（0=未修改，1=已修改）


## 注意事项

- 确保 `.env` 文件中的API配置正确
- 如果需要更精确结果，对生成速度不敏感，建议开启思考模式以获得更准确的结果

