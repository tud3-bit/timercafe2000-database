const API_BASE_URL = 'http://localhost:8080';
const REFRESH_INTERVAL_MS = 15000; // atualiza o grid a cada 15 segundos

// ─── COMPUTADORES ─────────────────────────────────────────────────────────────

async function listarPCsDisponiveis() {
    const gridElement = document.getElementById('pcGrid');

    gridElement.innerHTML = '<p style="color: #50BFE6;">Carregando...</p>';

    try {
        // Usa /computadores para exibir todos com seus status reais no grid
        const response = await fetch(`${API_BASE_URL}/computadores`);

        if (!response.ok) throw new Error(`HTTP ${response.status}`);

        const computadores = await response.json();
        gridElement.innerHTML = '';

        if (computadores.length === 0) {
            gridElement.innerHTML = '<p style="color: #50BFE6;">Nenhuma máquina encontrada.</p>';
            return;
        }

        computadores.forEach(pc => {
            const statusClass = getStatusClass(pc.STATUS);
            const pcDiv = document.createElement('div');
            pcDiv.className = 'pc-station';
            pcDiv.innerHTML = `
                <h2>${pc.NOME}</h2>
                <div class="pc-status ${statusClass}" title="${pc.STATUS}"></div>
                <p>R$ ${Number(pc.PRECO_HORA).toFixed(2)}/h</p>
                <small class="pc-status-label">${pc.STATUS}</small>
            `;
            gridElement.appendChild(pcDiv);
        });

    } catch (error) {
        console.error('❌ Erro ao buscar PCs no Backend:', error);
        gridElement.innerHTML = '<p style="color: #ff4757;">Erro ao conectar ao servidor.</p>';
    }
}

// Mapeia status do banco para classe CSS
function getStatusClass(status) {
    switch (status?.toUpperCase()) {
        case 'DISPONÍVEL':  return 'status-on';
        case 'OCUPADO':     return 'status-busy';
        case 'MANUTENÇÃO':  return 'status-maintenance';
        default:            return 'status-off';
    }
}

// ─── SESSÕES ATIVAS ───────────────────────────────────────────────────────────

async function atualizarSessoesAtivas() {
    try {
        const response = await fetch(`${API_BASE_URL}/sessoes-ativas`);
        if (!response.ok) return;
        const data = await response.json();
        document.getElementById('countAtivas').textContent = data.total ?? 0;
    } catch (error) {
        console.error('❌ Erro ao buscar sessões ativas:', error);
    }
}

// ─── INICIALIZAÇÃO ────────────────────────────────────────────────────────────

listarPCsDisponiveis();
atualizarSessoesAtivas();

// Atualização automática a cada 15 segundos
setInterval(() => {
    listarPCsDisponiveis();
    atualizarSessoesAtivas();
}, REFRESH_INTERVAL_MS);
