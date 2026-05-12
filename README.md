# Rastreabilidade Assistencial no SUS via Data Linkage

![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)
![DuckDB](https://img.shields.io/badge/DuckDB-0.10%2B-FFF000?style=for-the-badge&logo=duckdb&logoColor=black)
![PyArrow](https://img.shields.io/badge/PyArrow-Streaming-E25822?style=for-the-badge&logo=apache&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=for-the-badge&logo=jupyter&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-yellow?style=for-the-badge)

> **Auditoria da População de Pacientes (Jul/2024 – Jun/2025) entre RNDS e SIA/SIH utilizando CPF/CNS como Identificador Único**

---

## 📋 Descrição

Avaliação da integridade e completude do fluxo de dados assistenciais no SUS, verificando a sobreposição e as exclusões (pacientes) entre os sistemas de Regulação (**RNDS**) e Faturamento (**SIA/SIH**) para o período de julho de 2024 a junho de 2025.

A análise utiliza **CPF ou CNS** como chave de linkage, alinhando-se aos princípios da **Portaria 6.656/2025**.

> ⚠️ **Volumes massivos** — os dados são processados via **streaming com PyArrow** e **DuckDB in-process**, garantindo que não ocorra estouro de memória RAM, independentemente do tamanho dos arquivos CSV/Parquet.

---

## 🎯 Objetivos

| # | Objetivo |
|---|----------|
| 1 | **Comprovar rastreabilidade**: Proporção de pacientes concluídos na RNDS que efetivamente aparecem no faturamento (SIA/SIH). |
| 2 | **Identificar gargalos**: Proporção de pacientes faturados que não possuem registro de conclusão na RNDS. |
| 3 | **Validar a RNDS**: Demonstrar estatisticamente que os dados da RNDS fornecem base válida para estudos de fluxo assistencial e tempo de espera. |

---

## 🗂️ Estrutura do Projeto

```
ESTUDO_RNDS_SIA_SIH_AMOSTRA/
│
├── 📓 convert_csv_parquet.ipynb   # Conversão CSV → Parquet (streaming PyArrow + DuckDB)
├── 📓 estudo.ipynb                # Análise principal: limpeza, linkage e estatísticas
│
├── sql/
│   ├── RNDS.sql                   # Extração da base de Regulação (RNDS)
│   ├── SIA.sql                    # Extração do Sistema de Informação Ambulatorial
│   └── SIH.sql                    # Extração do Sistema de Informação Hospitalar
│
├── base/                          # Arquivos Parquet gerados (ignorados pelo git)
│   ├── RNDS.parquet
│   ├── SIA.parquet
│   └── SIH.parquet
│
├── analise_output/                # Resultados e saídas da análise (ignorados pelo git)
│
├── requirements.txt
├── .gitignore
└── README.md
```

---

## 🔄 Fluxo de Processamento

```
CSV (RNDS / SIA / SIH)
        │
        ▼
[ convert_csv_parquet.ipynb ]
  PyArrow Streaming + DuckDB
        │  chunk-by-chunk, sem carregar tudo na RAM
        ▼
  Parquet (compressão zstd)
        │
        ▼
[ estudo.ipynb ]
  DuckDB (in-process SQL)
        │
        ├─ Limpeza / Filtragem
        ├─ Renomeação de colunas
        ├─ Construção do Mapa CNS→CPF
        ├─ Linkage RNDS ↔ SIA/SIH
        └─ Estatísticas e Relatório Final
```

---

## 🏗️ Metodologia

### Etapa 1 — Extração e Conversão

Os dados são extraídos dos sistemas transacionais via SQL (Oracle) e exportados como CSV (separador `;`). O notebook `convert_csv_parquet.ipynb` converte cada arquivo para o formato **Parquet** com compressão **zstd** usando:

- **PyArrow CSV Streaming** (`pv.open_csv`): lê o arquivo por blocos sem carregar na RAM.
- **DuckDB**: alternativa para transformações SQL inline durante a conversão.

### Etapa 2 — Limpeza e Padronização

| Etapa | Ação |
|-------|------|
| SIA / SIH | Remove registros sem CPF **e** sem CNS simultaneamente |
| RNDS | Remove registros sem CPF; filtra status inválidos (`Falta`, `Pendente`, `Negado/Cancelado`, `Devolvido`, `Excluído`) |
| RNDS | Renomeia colunas para nomenclatura padrão (`CPF_PAC`, `CNS_PAC`, etc.) |

### Etapa 3 — Data Linkage

**Chave composta:** `{CPF_ou_CNS}|{COD_SIGTAP}|{MM/YYYY}`

O linkage utiliza **DuckDB** para joins e agregações em disco, evitando estouro de RAM:

```
RNDS (chaves) ──┐
                ├──► INTERSECT / EXCEPT ──► Matches + Gaps
SIA+SIH (chaves)┘
```

---

## 📊 Bases de Dados

| Base | Sistema | Período | Identificadores |
|------|---------|---------|-----------------|
| RNDS | Regulação | Jul/2024 – Jun/2025 | CPF + CNS |
| SIA | Faturamento Ambulatorial | Jul/2024 – Jun/2025 | CPF + CNS |
| SIH | Faturamento Hospitalar | Jul/2024 – Jun/2025 | CPF + CNS |

> Os dados são sensíveis e **não estão versionados** no repositório (`.gitignore`).

---

## ⚙️ Tecnologias

| Biblioteca | Uso |
|------------|-----|
| **DuckDB** | SQL in-process para linkage e análise — sem overflow de RAM |
| **PyArrow** | Streaming de CSV → Parquet, operações colunares |
| **Pandas** | Uso mínimo e pontual (apenas onde DuckDB não cobre) |
| **SQLite** | Fallback disk-based para operações de join massivas |
| **Jupyter** | Notebooks interativos |

---

## 🚀 Como Usar

### 1. Instalar dependências

```bash
pip install -r requirements.txt
```

### 2. Gerar os Parquets

Coloque os CSVs exportados na pasta `base/` e execute o notebook `convert_csv_parquet.ipynb` célula por célula (ou todas de uma vez).

> Os CSVs devem usar `;` como delimitador e encoding UTF-8.

### 3. Executar a análise

Abra e execute o notebook `estudo.ipynb` na ordem das células.

### Estrutura esperada de `base/`

```
base/
├── tb_ra_*.csv      # CSV da RNDS
├── SIA.csv          # CSV do SIA
└── SIH.csv          # CSV do SIH
```

---

## 🔐 Segurança e LGPD

- Dados de CPF e CNS são **dados pessoais sensíveis** (LGPD, Art. 11).
- Nenhum dado pessoal é versionado neste repositório.
- O processamento deve ocorrer em ambiente controlado e autorizado.
- Todos os acessos devem seguir a **Política de Segurança da Informação** da instituição.

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

## 👨‍💻 Autor

**Otavio Augusto**
📧 [otavioaugust@gmail.com](mailto:otavioaugust@gmail.com)

---

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor:

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📞 Suporte

Para dúvidas, issues ou sugestões, abra uma [GitHub Issue](../../issues).
