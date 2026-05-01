# LFSR Verification PoC Summary

## 이번 PoC의 방향

이번 PoC는 새 RTL을 자동 생성하는 것이 아니라, 이미 구현된 LFSR IP를 대상으로 여러 검증 방식을 붙여보는 흐름으로 재정의했다.

대상 IP:

- `rtl/configurable_lfsr.sv`
- `rtl/lfsr8.sv`
- `rtl/lfsr16.sv`
- `rtl/lfsr_csr.sv`

검증 목적:

```text
이미 개발된 RTL IP에 대해
1. Python golden model
2. Verilator
3. cocotb
4. Picker/Toffee
5. LLM4DV-style coverage feedback
6. UCAgent-style workflow
를 붙여보고, 어떤 흐름이 실제로 쓸 만한지 확인한다.
```

## 현재 실제로 사용한 것

### Python Golden Model

사용 파일:

- `tb/model_lfsr.py`
- `tb/test_lfsr_basic.py`
- `tb/test_lfsr_random.py`
- `tb/test_lfsr_csr.py`

역할:

- RTL과 독립적인 reference model
- reset/load/enable/zero-seed/period/CSR 동작 검증
- 빠른 regression

실행:

```bash
scripts/run_python_tests.sh
```

### Verilator

사용 파일:

- `tb/verilator_lfsr_tb.cpp`
- `tb/verilator_lfsr8_tb.cpp`
- `tb/verilator_lfsr16_tb.cpp`
- `tb/verilator_lfsr_csr_tb.cpp`

역할:

- RTL lint
- C++ smoke simulation
- Step 1 fixed LFSR 검증
- Step 3 CSR LFSR 검증

실행:

```bash
scripts/run_verilator_lint.sh all
scripts/run_verilator_step_tests.sh
scripts/run_verilator_sim.sh
```

### cocotb

사용 파일:

- `tb/cocotb/test_configurable_lfsr.py`
- `tb/cocotb/Makefile`

역할:

- Verilator backend 위에서 RTL을 Python으로 직접 drive
- Python golden model과 cycle-by-cycle 비교
- directed test와 random control stream test 수행

실행:

```bash
scripts/run_cocotb_tests.sh
```

현재 상태:

```text
cocotb + Verilator tests: PASS
```

## LLM4DV-style을 채용했다는 의미

### 원래 LLM4DV 개념

LLM4DV는 LLM을 hardware DV의 test stimulus generation에 사용하는 framework다. 핵심 구조는 다음과 같다.

```text
predefined coverage plan
-> LLM이 stimulus 생성
-> DUT/testbench 실행
-> coverage monitor가 covered/missed bin 계산
-> missed bin 정보를 다시 prompt로 제공
-> coverage가 오를 때까지 반복
```

공식 LLM4DV repo 설명에 따르면 목표는 LLM이 predefined coverage plan의 test bin을 가능한 적은 token으로 많이 cover하도록 stimulus를 생성하는 것이다. LLM4DV repo는 cocotb testbench가 포함된 benchmark design들을 제공하고, client/server 구조로 stimulus generation과 coverage feedback을 주고받는 흐름을 가진다.

### 이번 repo에서 구현한 것

사용 파일:

- `tb/llm4dv_lfsr/coverage_plan.json`
- `tb/llm4dv_lfsr/generate_stimulus.py`
- `tb/llm4dv_lfsr/run_stimulus.py`
- `scripts/run_llm4dv_lfsr.sh`

현재 구현한 구조:

```text
coverage_plan.json
-> generate_stimulus.py
-> stimulus.json
-> run_stimulus.py
-> Python golden model 실행
-> coverage_result.json
```

즉, 이번 repo에서는 LLM4DV의 핵심 아이디어인 coverage-feedback loop를 LFSR용으로 작게 구현했다.

현재 coverage bins:

- reset observed
- enable hold observed
- load seed observed
- zero seed observed
- non-zero seed observed
- all state bits toggled
- bit_o zero/one observed
- state returned to initial seed
- period reached
- random reset during active run
- random load during active run

실행:

```bash
scripts/run_llm4dv_lfsr.sh
```

현재 결과:

```text
coverage_ratio: 1.0
missing_bins: []
```

### 아직 하지 않은 것

중요한 구분:

```text
upstream ml4dv repo를 직접 붙인 것은 아니다.
LLM API를 호출해서 stimulus를 생성한 것도 아니다.
```

현재는 deterministic local generator다.

따라서 “LLM4DV-style”이라고 부르는 정확한 의미는:

```text
LLM4DV의 coverage plan -> stimulus generation -> coverage feedback 구조를
LFSR IP에 맞춰 로컬 scaffold로 구현했다.
```

다음 단계는 이 부분이다:

```text
missing_bins를 prompt로 변환
-> OpenAI-compatible API 또는 local LLM 호출
-> stimulus 후보 생성
-> run_stimulus.py로 coverage 측정
-> coverage가 부족하면 prompt를 갱신해 반복
```

## UCAgent-style을 채용했다는 의미

### 원래 UCAgent 개념

UCAgent는 LLM 기반 hardware unit-test verification agent다. 공식 문서 기준으로는 다음을 목표로 한다.

- 요구사항 이해
- 테스트 코드 생성/보완
- 테스트 실행
- coverage/report 생성
- bug analysis 문서화
- Picker/Toffee 기반 Python DUT 검증
- MCP를 통한 외부 code agent와 협업

UCAgent의 기본 전제는 Verilog DUT를 Picker로 Python package화하고, Toffee 기반으로 unit test verification을 구성하는 것이다.

### 이번 repo에서 구현한 것

사용 파일:

- `docs/ucagent_lfsr_workflow.md`
- `scripts/run_picker.sh`
- `scripts/run_toffee_picker_tests.sh`
- `tb/toffee_picker/test_lfsr_toffee_picker.py`

현재 구현한 UCAgent-style mapping:

| UCAgent-style 단계 | 현재 repo 구현 |
| --- | --- |
| DUT specification | `spec/lfsr_spec.md`, `spec/lfsr_steps.md` |
| DUT source | `rtl/configurable_lfsr.sv` |
| Picker DUT package | `build/picker/configurable_lfsr/` |
| Toffee/Picker test | `tb/toffee_picker/test_lfsr_toffee_picker.py` |
| Test command | `scripts/run_toffee_picker_tests.sh` |
| Coverage plan | `tb/llm4dv_lfsr/coverage_plan.json` |
| Summary/log | `build/verification_matrix.log` |

실행:

```bash
scripts/run_picker.sh
scripts/run_toffee_picker_tests.sh
```

현재 상태:

```text
Picker DUT generation: PASS
Toffee/Picker tests: PASS
```

### 아직 하지 않은 것

중요한 구분:

```text
UCAgent 자체를 설치하거나 실행한 것은 아니다.
```

현재는 UCAgent가 기대하는 workflow 구조를 repo 안에 맞춰놓은 상태다.

또한 현재 Toffee/Picker testbench는 최소 구조다. 아직 다음은 없다.

- reusable Toffee Agent class
- separate driver
- separate monitor
- scoreboard layer
- UCAgent가 생성한 test/report/bug-analysis 결과물

즉, “UCAgent-style”이라고 부르는 정확한 의미는:

```text
UCAgent가 사용할 수 있는 형태로
spec, DUT, Picker package, Toffee/Picker tests, coverage plan, execution command를 정리했다.
```

## UCAgent 설치 방법

공식 문서 기준 요구사항:

- Python 3.11+
- Linux 또는 macOS
- OpenAI-compatible API 접근 가능
- 메모리 4GB 이상 권장
- Picker 설치 필요
- Toffee/Picker 기반 검증 환경 권장

현재 이 repo는 이미 다음을 갖고 있다.

- Python `.venv`
- Picker 설치
- Toffee 설치
- Verilator/OSS CAD Suite
- `scripts/run_picker.sh`
- `scripts/run_toffee_picker_tests.sh`

### 설치 방법 1: pip로 GitHub main 설치

```bash
source .venv/bin/activate
pip install 'git+https://github.com/XS-MLVP/UCAgent@main'
ucagent --help
```

공식 문서에는 다음 형태도 제시되어 있다.

```bash
pip3 install git+https://git@github.com/XS-MLVP/UCAgent@main
ucagent --help
```

SSH 인증이 없는 환경에서는 `https://github.com/...` 형태가 더 편하다.

### 설치 방법 2: clone 후 local install

```bash
mkdir -p tools
git clone https://github.com/XS-MLVP/UCAgent.git tools/UCAgent
cd tools/UCAgent
source ../../.venv/bin/activate
pip install .
ucagent --help
```

### API key 설정

UCAgent는 LLM agent이므로 OpenAI-compatible API 접근이 필요하다.

일반적인 형태:

```bash
export OPENAI_API_KEY=<your_api_key>
export OPENAI_BASE_URL=<openai_compatible_endpoint_if_needed>
```

정확한 환경변수 이름은 사용하는 UCAgent config와 model backend에 맞춰 확인해야 한다.

## UCAgent를 설치하면 할 수 있는 일

설치 후 목표는 다음이다.

### 1. DUT 이해와 verification plan 생성

입력:

- `spec/lfsr_spec.md`
- `rtl/configurable_lfsr.sv`
- `rtl/lfsr_csr.sv`

기대 결과:

- 검증 목표 정리
- 기능별 test point 정리
- coverage 항목 정리
- edge case 정리

### 2. Toffee/Picker test 생성 또는 보강

입력:

- Picker-generated DUT package
- 기존 `tb/toffee_picker/test_lfsr_toffee_picker.py`
- Python golden model

기대 결과:

- directed test 추가
- random test 추가
- coverage point 추가
- scoreboard 구조 보강

### 3. 테스트 실행과 실패 분석

실행 대상:

```bash
scripts/run_toffee_picker_tests.sh
scripts/run_cocotb_tests.sh
scripts/run_llm4dv_lfsr.sh
scripts/run_verification_matrix.sh
```

기대 결과:

- 실패 로그 요약
- 원인 후보 분석
- 재현 절차 문서화
- 수정 제안

### 4. 보고서 생성

기대 산출물:

- test summary
- bug analysis
- coverage summary
- residual risk
- next action list

현재 repo에서는 이 역할을 수동 문서로 일부 대체하고 있다.

- `share.md`
- `Summary.md`
- `docs/ucagent_lfsr_workflow.md`

## 현재 Verification Matrix

전체 실행:

```bash
scripts/run_verification_matrix.sh
```

포함 항목:

- Python golden-model tests
- Verilator lint
- Verilator C++ tests
- cocotb + Verilator tests
- Picker DUT generation
- Toffee/Picker tests
- LLM4DV-style coverage-feedback run

최근 결과:

```text
Python tests: PASS
Verilator lint: PASS
Verilator C++ tests: PASS
cocotb tests: PASS
Toffee/Picker tests: PASS
LLM4DV-style coverage run: PASS
coverage_ratio: 1.0
missing_bins: []
```

## 결론

이번 PoC에서 실제로 달성한 것은 다음이다.

```text
이미 개발된 LFSR RTL IP를 대상으로
여러 검증 bench를 병렬로 붙이고
한 번에 regression으로 돌릴 수 있는 verification matrix를 만든 것
```

아직 남은 것은 다음이다.

```text
1. UCAgent 실제 설치 및 실행
2. UCAgent가 Toffee/Picker test를 자동 생성/보강하게 만들기
3. LLM4DV-style generator를 실제 LLM API 기반 stimulus generator로 교체
4. coverage miss -> prompt -> stimulus -> coverage feedback 반복 루프 자동화
```

## References

- UCAgent install docs: https://ucagent.open-verify.cc/content/01_start/01_installation/
- UCAgent introduction: https://open-verify.cc/mlvp/docs/ucagent/introduce/
- Picker setup docs: https://open-verify.cc/mlvp/en/docs/quick-start/installer/
- Picker usage docs: https://open-verify.cc/mlvp/en/docs/env_usage/picker_usage/
- Toffee overview: https://open-verify.cc/mlvp/en/docs/mlvp/
- Toffee PyPI: https://pypi.org/project/pytoffee/
- LLM4DV repo: https://github.com/ZixiBenZhang/ml4dv

