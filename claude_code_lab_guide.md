# 🤖 Claude Code 실습 가이드 - AI 업무 어시스턴트 만들기

## 실습 개요
- **목표**: Claude Code를 사용하여 처음부터 AI 웹 어시스턴트를 구축
- **소요 시간**: 2~3시간
- **난이도**: 중급 (RAG 실습 완료 후)
- **결과물**: Streamlit 기반 AI 업무 어시스턴트

---

## 사전 준비

### 1. 환경 확인
```bash
source ~/ai-training-env/bin/activate
which claude          # /usr/bin/claude 확인
python3 --version     # 3.11.x 확인
```

### 2. API 키 설정
```bash
# .env 파일에서 API 키 로드
export ANTHROPIC_API_KEY=$(grep ANTHROPIC_API_KEY ~/ai-training-projects/.env | cut -d= -f2)
export OPENAI_API_KEY=$(grep OPENAI_API_KEY ~/ai-training-projects/.env | cut -d= -f2)
```

### 3. 프로젝트 폴더 생성
```bash
mkdir -p ~/ai-training-projects/ai-assistant
cd ~/ai-training-projects/ai-assistant
```

---

## 실습 단계

### Step 1: Claude Code 실행 (10분)

```bash
claude
```

- 테마 선택: **1. Dark mode**
- 로그인: **1. Claude account with subscription**
- 브라우저에서 OAuth 인증 완료
- 프롬프트(박스) 입력창 확인

> 💡 **팁**: Shift+Enter = 줄바꿈, Enter = 전송

---

### Step 2: AI 업무 어시스턴트 생성 지시 (20분)

Claude Code 프롬프트에 입력:

```
Streamlit 기반 AI 업무 어시스턴트를 만들어줘. 기능: 1) PDF 업로드하면 AI 요약 2) 웹 URL 입력하면 내용 분석 3) 대화형 질의응답 4) 보고서 마크다운 생성 및 다운로드. 사용 API: OpenAI gpt-3.5-turbo. 한국어 UI. .env 파일은 ~/ai-training-projects/.env에 있음
```

- Claude Code가 파일 생성을 제안하면 **Yes** 선택
- 자동으로 `app.py` 생성됨

---

### Step 3: 앱 실행 및 테스트 (15분)

Claude Code에게 지시:

```
앱을 실행해줘
```

또는 직접 터미널에서:

```bash
streamlit run app.py --server.port=8502 --server.address=0.0.0.0
```

브라우저에서 접속: `http://<서버IP>:8502`

#### 테스트 항목:
- [ ] PDF 업로드 → 요약 확인
- [ ] 웹 URL 입력 → 분석 결과 확인
- [ ] 대화형 질의응답 동작 확인
- [ ] 보고서 다운로드 확인

---

### Step 4: 기능 추가 요청 (30분)

Claude Code에게 추가 기능을 요청해봅니다:

#### 예시 1: 감정 분석 탭 추가
```
새 탭을 추가해줘. "감정 분석" 탭에서 텍스트를 입력하면 긍정/부정/중립을 분석하고 점수를 보여줘.
```

#### 예시 2: 다국어 번역 기능
```
대화형 질의응답 탭에 번역 기능을 추가해줘. 사용자가 언어를 선택하면 해당 언어로 답변해줘.
```

#### 예시 3: UI 개선
```
사이드바에 모델 선택 옵션을 추가해줘. gpt-3.5-turbo와 gpt-4o-mini 중에서 선택할 수 있게.
```

#### 예시 4: 에러 처리
```
API 키가 없을 때 친절한 에러 메시지를 보여주고, PDF가 이미지 기반일 때 OCR 안내를 해줘.
```

> 💡 **포인트**: 자연어로 기능을 요청하면 Claude Code가 코드를 수정합니다.
> 매번 수정 후 브라우저를 새로고침하면 변경사항이 반영됩니다.

---

### Step 5: 버그 수정 체험 (15분)

의도적으로 에러를 발생시키고 Claude Code에게 수정 요청:

```
app.py 실행하면 에러가 발생해. 수정해줘.
```

또는 에러 메시지를 복사해서 붙여넣기:

```
이런 에러가 발생했어: ModuleNotFoundError: No module named 'xxx'. 해결해줘.
```

---

### Step 6: 커밋 및 정리 (10분)

Claude Code에게:

```
git 초기화하고 커밋해줘
```

또는 직접:

```bash
cd ~/ai-training-projects/ai-assistant
git init
git add app.py
git commit -m "AI 업무 어시스턴트 완성"
```

---

## 실습 포인트 정리

### Claude Code가 할 수 있는 것
| 기능 | 예시 |
|------|------|
| 코드 생성 | "Streamlit 앱 만들어줘" |
| 코드 수정 | "버튼 색상 바꿔줘" |
| 버그 수정 | "이 에러 고쳐줘" |
| 패키지 설치 | "필요한 패키지 설치해줘" |
| 파일 읽기 | "app.py 내용 보여줘" |
| 터미널 실행 | "앱 실행해줘" |
| Git 관리 | "커밋해줘" |

### 유용한 Claude Code 명령어
| 명령어 | 설명 |
|--------|------|
| `/help` | 도움말 |
| `/model` | 모델 변경 |
| `/exit` | 종료 |
| `/clear` | 대화 초기화 |
| `/theme` | 테마 변경 |

### 주의사항
- API 키가 포함된 파일은 절대 GitHub에 push하지 않기
- `.env` 파일은 `.gitignore`에 추가
- 실습 후 Streamlit 프로세스 종료: `Ctrl+C` 또는 `kill <PID>`

---

## 응용 과제 (시간 여유 시)

1. **Claude API로 전환**: OpenAI 대신 Anthropic Claude API 사용
2. **RAG 통합**: 이전 실습의 벡터 DB를 활용한 문서 검색 추가
3. **배포**: 외부 접속을 위한 포트포워딩 설정
