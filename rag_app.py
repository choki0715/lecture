import os
from dotenv import load_dotenv
load_dotenv("/home/ejkim/ai-training-projects/.env")

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage, AIMessage
import streamlit as st
import tempfile

st.set_page_config(layout="wide")
st.markdown("<h1 style='text-align: center; color: gray;'>PDF 문서 기반 RAG 시스템</h1>", unsafe_allow_html=True)
st.markdown("<h3 style='text-align: center; color: gray;'>PDF를 업로드하고 질문하세요</h3>", unsafe_allow_html=True)

def document_data(query, chat_history, vectorstore):
    llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0.7)
    
    # 관련 문서 검색
    docs = vectorstore.similarity_search(query, k=3)
    context = "\n\n".join([doc.page_content for doc in docs])
    
    # 프롬프트 구성
    prompt = f"""다음 문서 내용을 바탕으로 질문에 답변해주세요.

문서 내용:
{context}

질문: {query}

답변:"""
    
    response = llm.invoke(prompt)
    return {"answer": response.content}

if __name__ == '__main__':
    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
    uploaded_files = st.file_uploader("PDF 파일을 선택하세요", type="pdf", accept_multiple_files=True)

    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000, chunk_overlap=100,
        separators=["\n\n", "\n", " ", ""]
    )

    temp_dir = tempfile.TemporaryDirectory()
    docs = []

    for i, uploaded_file in enumerate(uploaded_files):
        st.write("파일:", i+1, uploaded_file.name)
        temp_filepath = os.path.join(temp_dir.name, uploaded_file.name)
        with open(temp_filepath, "wb") as f:
            f.write(uploaded_file.getvalue())
        loader = PyPDFLoader(temp_filepath)
        docs.extend(loader.load())

    if docs:
        with st.spinner("벡터 데이터베이스 구축 중..."):
            split_text = text_splitter.split_documents(documents=docs)
            vectorstore = FAISS.from_documents(split_text, embedding=embeddings)
        st.success("PDF 업로드 및 벡터 DB 구축 완료!")

        st.header(':blue[질문을 입력해 주세요]', divider='rainbow')
        prompt = st.chat_input("질문을 입력하세요")

        if "user_prompt_history" not in st.session_state:
            st.session_state["user_prompt_history"] = []
        if "chat_answers_history" not in st.session_state:
            st.session_state["chat_answers_history"] = []
        if "chat_history" not in st.session_state:
            st.session_state["chat_history"] = []

        if prompt:
            with st.spinner("답변 생성 중..."):
                output = document_data(
                    query=prompt,
                    chat_history=st.session_state["chat_history"],
                    vectorstore=vectorstore
                )
                st.session_state["chat_answers_history"].append(output['answer'])
                st.session_state["user_prompt_history"].append(prompt)
                st.session_state["chat_history"].append((prompt, output['answer']))

        if st.session_state["chat_answers_history"]:
            for answer, question in zip(st.session_state["chat_answers_history"],
                                        st.session_state["user_prompt_history"]):
                message1 = st.chat_message("user")
                message1.write(question)
                message2 = st.chat_message("assistant")
                message2.write(answer)
