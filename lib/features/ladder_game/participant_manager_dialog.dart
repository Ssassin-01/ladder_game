import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/neon_theme.dart';
import '../../core/neon_button.dart';
import 'ladder_game_view_model.dart';
import '../../core/sound_manager.dart';

class ParticipantManagerDialog extends StatefulWidget {
  const ParticipantManagerDialog({super.key});

  @override
  State<ParticipantManagerDialog> createState() => _ParticipantManagerDialogState();
}

class _ParticipantManagerDialogState extends State<ParticipantManagerDialog> {
  // 각 참가자의 이름 컨트롤러 리스트
  final List<TextEditingController> _nameControllers = [];
  // 각 컨트롤러의 포커스 노드 (키보드가 해당 항목을 가리지 않도록)
  final List<FocusNode> _focusNodes = [];
  // 스크롤 컨트롤러 (키보드 올라올 때 해당 항목으로 스크롤)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<LadderGameViewModel>();
    _rebuildControllers(viewModel);
  }

  void _rebuildControllers(LadderGameViewModel viewModel) {
    // 기존 컨트롤러/포커스 해제
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _nameControllers.clear();
    _focusNodes.clear();

    for (int i = 0; i < viewModel.playerCount; i++) {
      final p = viewModel.currentParticipants[i];
      _nameControllers.add(TextEditingController(text: p.customName ?? p.animalType));
      final fn = FocusNode();
      // 포커스 될 때 해당 항목이 보이게 스크롤
      fn.addListener(() {
        if (fn.hasFocus) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (_scrollController.hasClients) {
              final idx = _focusNodes.indexOf(fn);
              final targetOffset = idx * 68.0; // 각 행 높이
              _scrollController.animateTo(
                targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
      _focusNodes.add(fn);
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // 이름 변경 저장 후 명단 관리 다이얼로그 닫기
  void _saveAndClose() {
    final viewModel = context.read<LadderGameViewModel>();
    for (int i = 0; i < _nameControllers.length; i++) {
      viewModel.updateParticipantName(i, _nameControllers[i].text);
    }
    SoundManager().playTick();
    // 변경 반영 후 팝업 닫기
    viewModel.setPlayerCount(viewModel.playerCount);
    Navigator.pop(context);
  }

  // 동물 아이콘 선택 팝업
  void _showAnimalPicker(int index) {
    final viewModel = context.read<LadderGameViewModel>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonColors.darkCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: NeonColors.hotPink, width: 2),
        ),
        title: const Text('동물 선택', style: TextStyle(color: NeonColors.hotPink)),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: viewModel.allAvailableParticipants.length,
            itemBuilder: (_, i) {
              final animal = viewModel.allAvailableParticipants[i];
              return GestureDetector(
                onTap: () {
                  SoundManager().playTick();
                  viewModel.changeParticipantAnimal(index, animal);
                  // 이름도 동물 이름으로 초기화
                  setState(() {
                    _nameControllers[index].text = animal.animalType;
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(animal.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  // 명단 저장 팝업
  void _showSaveDialog() {
    final viewModel = context.read<LadderGameViewModel>();
    // 저장 전 이름 먼저 반영
    for (int i = 0; i < _nameControllers.length; i++) {
      viewModel.updateParticipantName(i, _nameControllers[i].text);
    }
    showDialog(
      context: context,
      builder: (ctx) {
        String presetName = '';
        return AlertDialog(
          backgroundColor: NeonColors.darkCharcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: NeonColors.limeGreen, width: 2),
          ),
          title: const Text('명단 저장', style: TextStyle(color: NeonColors.limeGreen)),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '저장할 이름 입력',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            autofocus: true,
            onChanged: (val) => presetName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                if (presetName.trim().isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navCtx = Navigator.of(ctx);
                  final navThis = Navigator.of(context);
                  await viewModel.saveCurrentParticipants(presetName.trim());
                  navCtx.pop(); // 저장 다이얼로그 닫기
                  navThis.pop(); // 명단 관리 다이얼로그도 닫기
                  messenger.showSnackBar(SnackBar(
                    content: Text("'$presetName' 명단이 저장되었습니다."),
                    backgroundColor: NeonColors.limeGreen.withAlpha(200),
                  ));
                }
              },
              child: const Text('저장', style: TextStyle(color: NeonColors.limeGreen)),
            ),
          ],
        );
      },
    );
  }

  // 명단 불러오기 팝업
  void _showLoadDialog() async {
    final viewModel = context.read<LadderGameViewModel>();
    final lists = await viewModel.getSavedLists();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NeonColors.darkCharcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.orangeAccent, width: 2),
          ),
          title: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text('명단 불러오기', style: TextStyle(color: Colors.orangeAccent)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: lists.isEmpty
                ? const Center(
                    child: Text('저장된 명단이 없습니다.', style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (_, i) {
                      return ListTile(
                        leading: const Icon(Icons.people, color: Colors.orangeAccent),
                        title: Text(lists[i], style: const TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final nav = Navigator.of(ctx);
                            await viewModel.deleteParticipantList(lists[i]);
                            nav.pop();
                          },
                        ),
                        onTap: () async {
                          final nav = Navigator.of(ctx);
                          await viewModel.loadParticipantList(lists[i]);
                          nav.pop();
                          // 불러온 뒤 컨트롤러 재빌드
                          if (mounted) {
                            setState(() => _rebuildControllers(viewModel));
                          }
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();

    // 참가자 수가 변경되었을 때 컨트롤러 재빌드
    if (_nameControllers.length != viewModel.playerCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _rebuildControllers(viewModel));
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: NeonColors.darkCharcoal,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: NeonColors.cyan, width: 2),
          boxShadow: [
            BoxShadow(
              color: NeonColors.cyan.withAlpha(60),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _saveAndClose,
                    icon: const Icon(Icons.arrow_back_ios, size: 20, color: NeonColors.cyan),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '참가자 명단 관리',
                      style: TextStyle(
                        color: NeonColors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: NeonColors.getGlow(NeonColors.cyan),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 인원 증감 버튼
                  _buildCountButton(Icons.remove, () {
                    if (viewModel.playerCount > 2) {
                      viewModel.setPlayerCount(viewModel.playerCount - 1);
                    }
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${viewModel.playerCount}명',
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  _buildCountButton(Icons.add, () {
                    if (viewModel.playerCount < 20) {
                      viewModel.setPlayerCount(viewModel.playerCount + 1);
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            // 참가자 리스트 (스크롤 + 키보드 회피)
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shrinkWrap: true,
                itemCount: viewModel.playerCount,
                itemBuilder: (_, i) {
                  if (i >= _nameControllers.length || i >= _focusNodes.length) {
                    return const SizedBox();
                  }
                  final p = viewModel.currentParticipants[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // 동물 아이콘 (터치 시 선택 팝업)
                        GestureDetector(
                          onTap: () {
                            SoundManager().playTick();
                            _showAnimalPicker(i);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NeonColors.cyan.withAlpha(80)),
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Text(p.emoji, style: const TextStyle(fontSize: 26)),
                                  Container(
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: NeonColors.hotPink,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 9),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 이름 입력 필드
                        Expanded(
                          child: TextFormField(
                            controller: _nameControllers[i],
                            focusNode: _focusNodes[i],
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: '이름 입력',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withAlpha(15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: NeonColors.cyan, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              viewModel.updateParticipantName(i, val);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12),
            // 하단 버튼들
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: NeonButton(
                          text: '불러오기',
                          width: double.infinity,
                          height: 44,
                          color: Colors.orangeAccent,
                          onPressed: () {
                            SoundManager().playTick();
                            _showLoadDialog();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeonButton(
                          text: '명단 저장',
                          width: double.infinity,
                          height: 44,
                          color: NeonColors.limeGreen,
                          onPressed: () {
                            SoundManager().playTick();
                            _showSaveDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        SoundManager().playTick();
        onTap();
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NeonColors.cyan.withAlpha(100)),
        ),
        child: Icon(icon, color: NeonColors.cyan, size: 18),
      ),
    );
  }
}
