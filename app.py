"""
AI 채팅 데모 - Streamlit 예제 앱
"""
import streamlit as st

# 페이지 설정
st.set_page_config(
    page_title="AI 채팅 데모",
    page_icon="🤖",
    layout="wide"
)

# 타이틀
st.title("🤖 AI 채팅 데모")
st.markdown("---")

# 사이드바
with st.sidebar:
    st.header("⚙️ 설정")
    model_name = st.selectbox(
        "모델 선택",
        ["Llama-3-8B", "Llama-3.1-8B", "Custom Model"]
    )
    temperature = st.slider("Temperature", 0.0, 2.0, 0.7)
    max_tokens = st.slider("Max Tokens", 50, 2000, 512)
    
    st.markdown("---")
    st.markdown("### 📊 모델 정보")
    st.info(f"선택된 모델: {model_name}")

# 채팅 히스토리 초기화
if "messages" not in st.session_state:
    st.session_state.messages = []

# 채팅 메시지 표시
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# 사용자 입력
if prompt := st.chat_input("메시지를 입력하세요..."):
    # 사용자 메시지 추가
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # AI 응답 (데모용 - 실제로는 모델 호출 필요)
    with st.chat_message("assistant"):
        response = f"[{model_name}] 안녕하세요! 저는 AI 어시스턴트입니다. '{prompt}'에 대해 답변드리겠습니다."
        st.markdown(response)
        st.session_state.messages.append({"role": "assistant", "content": response})

# 하단 정보
st.markdown("---")
col1, col2, col3 = st.columns(3)
with col1:
    st.metric("대화 수", len(st.session_state.messages) // 2)
with col2:
    st.metric("Temperature", temperature)
with col3:
    st.metric("Max Tokens", max_tokens)

# 채팅 초기화 버튼
if st.button("🗑️ 채팅 초기화"):
    st.session_state.messages = []
    st.rerun()
