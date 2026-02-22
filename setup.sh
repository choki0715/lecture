#!/bin/bash

#===============================================================================
# AI 교육 환경 설정 스크립트
# Ubuntu 24.04 LTS 지원
#
# 포함 내용:
# 1. VSCode 설치
# 2. Claude Code CLI 설치
# 3. LLM Fine-tuning 환경 (HuggingFace + PEFT + PyTorch + CUDA)
# 4. Streamlit 웹 서비스 환경
# 5. RAG 환경 (LangChain + FAISS + OpenAI)
# 6. 한국어 NLP (KoNLPy)
#
# 변경 이력:
# v2.0 - Ubuntu 24.04 호환, 안정 버전 고정, Python 기본값 복구
# v2.1 - 노트북 다운로드 방식 변경
# v3.0 - Unsloth 제거, 패키지 버전 호환성 수정, RAG/KoNLPy 추가
#        transformers==4.46.0 + trl==0.12.0 + peft==0.14.0 호환 조합
#        멀티 GPU 충돌 방지 (CUDA_VISIBLE_DEVICES)
#        .env API 키 자동 로드
# v3.1 - 필요한 실습 파일만 다운로드, nltk 데이터 포함
#===============================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║           AI 교육 환경 설정 스크립트 (AIDENTIFY) v3.1            ║"
    echo "║                                                                    ║"
    echo "║  • VSCode + Claude Code CLI                                        ║"
    echo "║  • LLM Fine-tuning (HuggingFace + PEFT + LoRA)                    ║"
    echo "║  • RAG (LangChain + FAISS + OpenAI)                                ║"
    echo "║  • Streamlit + 한국어 NLP (KoNLPy)                                 ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
}

#===============================================================================
# 안정 버전 정의 (호환성 테스트 완료 조합)
#===============================================================================
TORCH_VERSION="2.6.0"
TORCHVISION_VERSION="0.21.0"
CUDA_INDEX="https://download.pytorch.org/whl/cu124"
PYTHON_VERSION="3.11"

# HuggingFace 호환 조합 (테스트 완료)
TRANSFORMERS_VERSION="4.46.0"
TRL_VERSION="0.12.0"
PEFT_VERSION="0.14.0"
BITSANDBYTES_VERSION="0.45.0"

#-------------------------------------------------------------------------------
# 시스템 사전 요구사항 확인
#-------------------------------------------------------------------------------
check_requirements() {
    log_info "시스템 요구사항 확인 중..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            log_error "이 스크립트는 Ubuntu에서만 지원됩니다."
            exit 1
        fi
        log_info "OS: $PRETTY_NAME"
        
        if [[ "$VERSION_ID" != "24.04" && "$VERSION_ID" != "22.04" ]]; then
            log_warning "이 스크립트는 Ubuntu 22.04/24.04에서 테스트되었습니다. 현재: $VERSION_ID"
        fi
    fi
    
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    log_info "시스템 메모리: ${TOTAL_MEM}GB"
    if [ "$TOTAL_MEM" -lt 16 ]; then
        log_warning "최소 16GB RAM을 권장합니다. 현재: ${TOTAL_MEM}GB"
    fi
    
    FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    log_info "사용 가능한 디스크 공간: ${FREE_SPACE}GB"
    if [ "$FREE_SPACE" -lt 50 ]; then
        log_warning "최소 50GB 여유 공간을 권장합니다. 현재: ${FREE_SPACE}GB"
    fi
    
    if command -v nvidia-smi &> /dev/null; then
        log_success "NVIDIA GPU 감지됨"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
        HAS_GPU=true
    else
        log_warning "NVIDIA GPU가 감지되지 않음. CPU 모드로 설치됩니다."
        HAS_GPU=false
    fi
}

#-------------------------------------------------------------------------------
# 시스템 패키지 업데이트
#-------------------------------------------------------------------------------
update_system() {
    log_info "시스템 패키지 업데이트 중..."
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y \
        curl wget git build-essential \
        software-properties-common apt-transport-https \
        ca-certificates gnupg lsb-release unzip jq \
        default-jdk
    log_success "시스템 업데이트 완료"
}

#-------------------------------------------------------------------------------
# VSCode 설치
#-------------------------------------------------------------------------------
install_vscode() {
    log_info "Visual Studio Code 설치 중..."
    
    if command -v code &> /dev/null; then
        log_success "VSCode가 이미 설치되어 있습니다."
        return
    fi
    
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm packages.microsoft.gpg
    
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y code
    
    log_success "VSCode 설치 완료"
}

#-------------------------------------------------------------------------------
# Node.js 설치
#-------------------------------------------------------------------------------
install_nodejs() {
    log_info "Node.js 설치 중..."
    
    if command -v node &> /dev/null; then
        log_success "Node.js가 이미 설치되어 있습니다: $(node --version)"
        return
    fi
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    log_success "Node.js $(node --version) 설치 완료"
}

#-------------------------------------------------------------------------------
# Claude Code CLI 설치
#-------------------------------------------------------------------------------
install_claude_code() {
    log_info "Claude Code CLI 설치 중..."
    
    if command -v claude &> /dev/null; then
        log_success "Claude Code가 이미 설치되어 있습니다."
        return
    fi
    
    sudo npm install -g @anthropic-ai/claude-code
    log_success "Claude Code CLI 설치 완료"
}

#-------------------------------------------------------------------------------
# Python 환경 설정
#-------------------------------------------------------------------------------
install_python() {
    log_info "Python 환경 설정 중..."
    
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y \
        python3.11 python3.11-venv python3.11-dev python3-pip
    
    python3.11 -m pip install --upgrade pip --break-system-packages 2>/dev/null || \
    python3.11 -m pip install --upgrade pip
    
    log_success "Python $(python3.11 --version) 설치 완료"
}

#-------------------------------------------------------------------------------
# CUDA Toolkit 설치
#-------------------------------------------------------------------------------
install_cuda() {
    if [ "$HAS_GPU" = false ]; then
        log_warning "GPU가 없어 CUDA 설치를 건너뜁니다."
        return
    fi
    
    log_info "CUDA Toolkit 설치 중..."
    
    if command -v nvcc &> /dev/null; then
        log_success "CUDA가 이미 설치되어 있습니다."
        return
    fi
    
    . /etc/os-release
    if [[ "$VERSION_ID" == "24.04" ]]; then
        CUDA_REPO="ubuntu2404"
    else
        CUDA_REPO="ubuntu2204"
    fi
    
    wget "https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_REPO}/x86_64/cuda-keyring_1.1-1_all.deb"
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb
    
    sudo apt-get update
    sudo apt-get install -y cuda-toolkit
    
    if ! grep -q "cuda" ~/.bashrc; then
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    fi
    
    log_success "CUDA 설치 완료"
}

#-------------------------------------------------------------------------------
# LLM 환경 설정 (HuggingFace + PEFT)
#-------------------------------------------------------------------------------
setup_llm_environment() {
    log_info "LLM Fine-tuning 환경 설정 중..."
    
    VENV_DIR="$HOME/ai-training-env"
    
    if [ -d "$VENV_DIR" ]; then
        log_warning "기존 가상환경을 발견했습니다. 백업 후 재생성합니다."
        mv "$VENV_DIR" "${VENV_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    python3.11 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    
    pip install --upgrade pip setuptools wheel
    
    # PyTorch
    if [ "$HAS_GPU" = true ]; then
        log_info "GPU 환경으로 PyTorch ${TORCH_VERSION} 설치 중..."
        pip install \
            "torch==${TORCH_VERSION}" \
            "torchvision==${TORCHVISION_VERSION}" \
            "torchaudio==${TORCH_VERSION}" \
            --index-url "${CUDA_INDEX}"
    else
        log_info "CPU 환경으로 PyTorch ${TORCH_VERSION} 설치 중..."
        pip install \
            "torch==${TORCH_VERSION}" \
            "torchvision==${TORCHVISION_VERSION}" \
            "torchaudio==${TORCH_VERSION}" \
            --index-url https://download.pytorch.org/whl/cpu
    fi
    
    if [ "$HAS_GPU" = true ]; then
        python -c "import torch; assert torch.cuda.is_available(), 'GPU not detected!'; print(f'GPU: {torch.cuda.get_device_name(0)}')"
    fi
    
    # 핵심 ML 패키지
    log_info "핵심 ML 패키지 설치 중..."
    pip install \
        "transformers==${TRANSFORMERS_VERSION}" \
        "trl==${TRL_VERSION}" \
        "peft==${PEFT_VERSION}" \
        "bitsandbytes>=${BITSANDBYTES_VERSION}" \
        "datasets>=3.0.0" \
        "accelerate>=1.2.0" \
        "sentencepiece" \
        "protobuf" \
        "safetensors"
    
    # NLP / 임베딩
    log_info "NLP 패키지 설치 중..."
    pip install \
        gensim nltk konlpy sentence-transformers

    # nltk 데이터 다운로드
    python -c "import nltk; nltk.download('punkt'); nltk.download('punkt_tab')"
    
    # RAG
    log_info "RAG 패키지 설치 중..."
    pip install \
        langchain langchain-community langchain-openai \
        langchain-text-splitters faiss-cpu \
        pypdf python-dotenv beautifulsoup4 requests
    
    # Jupyter
    log_info "Jupyter 환경 설치 중..."
    pip install jupyter jupyterlab ipywidgets ipykernel
    python -m ipykernel install --user --name=ai-training --display-name="ai-training-env"
    
    # Streamlit
    log_info "Streamlit 설치 중..."
    pip install streamlit
    
    # 확인
    log_info "설치된 주요 패키지 버전:"
    python -c "
import torch
print(f'  PyTorch: {torch.__version__}')
print(f'  CUDA: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f'  GPU {i}: {torch.cuda.get_device_name(i)}')
import transformers; print(f'  Transformers: {transformers.__version__}')
import trl; print(f'  TRL: {trl.__version__}')
import peft; print(f'  PEFT: {peft.__version__}')
import bitsandbytes; print(f'  BitsAndBytes: {bitsandbytes.__version__}')
import gensim; print(f'  Gensim: {gensim.__version__}')
import streamlit; print(f'  Streamlit: {streamlit.__version__}')
import langchain; print(f'  LangChain: {langchain.__version__}')
"
    
    deactivate
    log_success "LLM Fine-tuning 환경 설정 완료"
}

#-------------------------------------------------------------------------------
# 실습 파일 다운로드 (필요한 파일만)
#-------------------------------------------------------------------------------
setup_example_project() {
    log_info "예제 프로젝트 설정 중..."
    
    PROJECT_DIR="$HOME/ai-training-projects"
    LECTURE_DIR="$PROJECT_DIR/lecture"
    mkdir -p "$LECTURE_DIR"
    cd "$LECTURE_DIR"
    
    BASE_URL="https://raw.githubusercontent.com/choki0715/lecture/master"
    FILES=(
        "tokenization.ipynb"
        "word2vec_embedding.ipynb"
        "fasttext_embedding.ipynb"
        "quant_simple.ipynb"
        "quant_perform.ipynb"
        "quantization_comparison.ipynb"
        "lora_finetuning.ipynb"
        "app.py"
        "rag_app.py"
        "train_data.csv"
        "a_poor_dog.txt"
        "claude_code_lab_guide.md"
    )
    
    log_info "실습 파일 다운로드 중..."
    for f in "${FILES[@]}"; do
        wget -q "${BASE_URL}/${f}" -O "${f}" && log_info "  ✓ ${f}" || log_warning "  ✗ ${f} 다운로드 실패"
    done
    
    # Claude Code 실습 폴더
    mkdir -p "$PROJECT_DIR/ai-assistant"
    
    log_success "예제 프로젝트 설정 완료: $PROJECT_DIR"
}

#-------------------------------------------------------------------------------
# 환경 변수 설정
#-------------------------------------------------------------------------------
setup_environment_variables() {
    log_info "환경 변수 설정 중..."
    
    if grep -q "AI Training Environment" ~/.bashrc 2>/dev/null; then
        log_warning "환경 변수가 이미 설정되어 있습니다. 건너뜁니다."
        return
    fi
    
    cat >> ~/.bashrc << 'EOF'

# ====== AI Training Environment v3.1 ======
export AI_TRAINING_HOME="$HOME/ai-training-projects"
export AI_VENV="$HOME/ai-training-env"

# 멀티 GPU 충돌 방지 (기본 GPU 0번만 사용)
export CUDA_VISIBLE_DEVICES=0

# .env에서 API 키 자동 로드
if [ -f "$HOME/ai-training-projects/.env" ]; then
    export $(grep -v '^#' "$HOME/ai-training-projects/.env" | xargs)
fi

# 가상환경 활성화 함수
activate_ai() {
    source "$AI_VENV/bin/activate"
    echo "AI Training 가상환경이 활성화되었습니다."
}

# Jupyter Lab 시작 함수
start_jupyter() {
    source "$AI_VENV/bin/activate"
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
}

# Streamlit 앱 시작 함수
start_streamlit() {
    source "$AI_VENV/bin/activate"
    streamlit run "$1" --server.port=8501 --server.address=0.0.0.0
}

# HuggingFace 캐시
export HF_HOME="$HOME/.cache/huggingface"
export TRANSFORMERS_CACHE="$HOME/.cache/huggingface/transformers"

# wandb 비활성화
export WANDB_DISABLED=true

# Alias
alias ai='activate_ai'
alias jlab='start_jupyter'
alias sl='start_streamlit'
EOF

    log_success "환경 변수 설정 완료"
}

#-------------------------------------------------------------------------------
# 설치 완료 정보 출력
#-------------------------------------------------------------------------------
print_completion_info() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ 설치가 완료되었습니다!                       ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📁 설치된 위치:"
    echo "   • 가상환경: $HOME/ai-training-env"
    echo "   • 프로젝트: $HOME/ai-training-projects"
    echo "   • 실습 노트북: $HOME/ai-training-projects/lecture"
    echo ""
    echo "🚀 빠른 시작:"
    echo "   1. source ~/.bashrc"
    echo "   2. ai              (가상환경 활성화)"
    echo "   3. jlab            (Jupyter Lab)"
    echo "   4. sl <app.py>     (Streamlit)"
    echo "   5. claude          (Claude Code)"
    echo ""
    echo "📓 실습 노트북:"
    echo "   • tokenization.ipynb        - 토큰화"
    echo "   • word2vec_embedding.ipynb   - Word2Vec"
    echo "   • fasttext_embedding.ipynb   - FastText (nltk vs KoNLPy)"
    echo "   • quant_simple.ipynb         - 양자화 크기 비교"
    echo "   • quant_perform.ipynb        - 양자화 품질 비교"
    echo "   • quantization_comparison.ipynb - BnB vs GGUF"
    echo "   • lora_finetuning.ipynb      - LoRA Fine-tuning"
    echo "   • rag_app.py                 - RAG (PDF + OpenAI)"
    echo "   • claude_code_lab_guide.md   - Claude Code 실습 가이드"
    echo ""
    echo "📋 API 키 설정: ~/ai-training-projects/.env"
    echo "   OPENAI_API_KEY=sk-..."
    echo "   ANTHROPIC_API_KEY=sk-ant-..."
    echo ""
}

#-------------------------------------------------------------------------------
# 메인 실행
#-------------------------------------------------------------------------------
main() {
    print_banner
    check_requirements
    update_system
    install_vscode
    install_nodejs
    install_claude_code
    install_python
    install_cuda
    setup_llm_environment
    setup_example_project
    setup_environment_variables
    print_completion_info
}

case "${1:-}" in
    --vscode-only)   update_system; install_vscode ;;
    --claude-only)   install_nodejs; install_claude_code ;;
    --llm-only)      check_requirements; install_python; install_cuda; setup_llm_environment ;;
    --project-only)  setup_example_project ;;
    --help)
        echo "사용법: $0 [옵션]"
        echo "  (없음)            전체 설치"
        echo "  --vscode-only     VSCode만 설치"
        echo "  --claude-only     Claude Code만 설치"
        echo "  --llm-only        LLM 환경만 설치"
        echo "  --project-only    프로젝트만 설정"
        echo "  --help            도움말 표시"
        ;;
    *) main ;;
esac