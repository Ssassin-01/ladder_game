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
  final List<TextEditingController> _nameControllers = [];
  final List<FocusNode> _focusNodes = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<LadderGameViewModel>();
    _rebuildControllers(viewModel);
  }

  void _rebuildControllers(LadderGameViewModel viewModel) {
    for (final c in _nameControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _nameControllers.clear();
    _focusNodes.clear();

    for (int i = 0; i < viewModel.playerCount; i++) {
      final p = viewModel.currentParticipants[i];
      _nameControllers.add(TextEditingController(text: p.customName ?? p.animalType));
      final fn = FocusNode();
      fn.addListener(() {
        if (fn.hasFocus && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 350), () {
            final idx = _focusNodes.indexOf(fn);
            final targetOffset = idx * 64.0;
            _scrollController.animateTo(
              targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      });
      _focusNodes.add(fn);
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final viewModel = context.read<LadderGameViewModel>();
    for (int i = 0; i < _nameControllers.length; i++) {
      viewModel.updateParticipantName(i, _nameControllers[i].text);
    }
    SoundManager().playTick();
    viewModel.setPlayerCount(viewModel.playerCount);
    Navigator.pop(context);
  }

  void _showAnimalPicker(int index) {
    final viewModel = context.read<LadderGameViewModel>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: NeonColors.primary, width: 2),
        ),
        title: const Text('동물 선택', style: TextStyle(color: NeonColors.primary, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: viewModel.allAvailableParticipants.length,
            itemBuilder: (_, i) {
              final animal = viewModel.allAvailableParticipants[i];
              return GestureDetector(
                onTap: () {
                  SoundManager().playTick();
                  viewModel.changeParticipantAnimal(index, animal);
                  setState(() {
                    _nameControllers[index].text = animal.animalType;
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NeonColors.textSub.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(animal.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: NeonColors.textSub)),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog() {
    final viewModel = context.read<LadderGameViewModel>();
    for (int i = 0; i < _nameControllers.length; i++) {
      viewModel.updateParticipantName(i, _nameControllers[i].text);
    }
    showDialog(
      context: context,
      builder: (ctx) {
        String presetName = '';
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: const BorderSide(color: NeonColors.primary, width: 2),
          ),
          title: const Text('명단 저장', style: TextStyle(color: NeonColors.primary, fontWeight: FontWeight.bold)),
          content: TextField(
            style: const TextStyle(color: NeonColors.textMain),
            decoration: const InputDecoration(
              hintText: '저장할 이름을 입력하세요',
              hintStyle: TextStyle(color: NeonColors.textSub),
            ),
            autofocus: true,
            onChanged: (val) => presetName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: NeonColors.textSub)),
            ),
            TextButton(
              onPressed: () async {
                if (presetName.trim().isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navCtx = Navigator.of(ctx);
                  final navThis = Navigator.of(context);
                  await viewModel.saveCurrentParticipants(presetName.trim());
                  navCtx.pop();
                  navThis.pop();
                  messenger.showSnackBar(SnackBar(
                    content: Text("'$presetName' 명단이 저장되었습니다."),
                    backgroundColor: NeonColors.primary,
                  ));
                }
              },
              child: const Text('저장', style: TextStyle(color: NeonColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showLoadDialog() async {
    final viewModel = context.read<LadderGameViewModel>();
    final lists = await viewModel.getSavedLists();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: const BorderSide(color: NeonColors.primary, width: 2),
          ),
          title: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.arrow_back_ios, color: NeonColors.textSub, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text('명단 불러오기', style: TextStyle(color: NeonColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: lists.isEmpty
                ? const Center(
                    child: Text('저장된 명단이 없습니다.', style: TextStyle(color: NeonColors.textSub)),
                  )
                : ListView.separated(
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E0D5)),
                    itemBuilder: (_, i) {
                      return ListTile(
                        leading: const Icon(Icons.people_outline, color: NeonColors.primary, size: 20),
                        title: Text(lists[i], style: const TextStyle(color: NeonColors.textMain, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFBE2D06), size: 20),
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
                          if (mounted) setState(() => _rebuildControllers(viewModel));
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: NeonColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: NeonColors.primary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _saveAndClose,
                    icon: const Icon(Icons.close, size: 22, color: NeonColors.textSub),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '명단 관리',
                      style: TextStyle(
                        color: NeonColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildCountButton(Icons.remove, () {
                    if (viewModel.playerCount > 2) {
                      viewModel.setPlayerCount(viewModel.playerCount - 1);
                    }
                  }),
                  const SizedBox(width: 12),
                  Text(
                    '${viewModel.playerCount}명',
                    style: const TextStyle(
                      color: NeonColors.textMain, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  _buildCountButton(Icons.add, () {
                    if (viewModel.playerCount < 20) {
                      viewModel.setPlayerCount(viewModel.playerCount + 1);
                    }
                  }),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E0D5)),
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shrinkWrap: true,
                itemCount: viewModel.playerCount,
                itemBuilder: (_, i) {
                  if (i >= _nameControllers.length) return const SizedBox();
                  final p = viewModel.currentParticipants[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            SoundManager().playTick();
                            _showAnimalPicker(i);
                          },
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F7F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: NeonColors.textSub.withValues(alpha: 0.1)),
                            ),
                            child: Center(
                              child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameControllers[i],
                            focusNode: _focusNodes[i],
                            style: const TextStyle(color: NeonColors.textMain, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: '이름 입력',
                              hintStyle: const TextStyle(color: NeonColors.textSub),
                              filled: true,
                              fillColor: const Color(0xFFF9F7F2).withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (val) => viewModel.updateParticipantName(i, val),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E0D5)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        SoundManager().playTick();
                        _showLoadDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NeonColors.primary,
                        side: BorderSide(color: NeonColors.primary.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('불러오기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      text: '명단 저장',
                      width: double.infinity,
                      height: 48,
                      color: NeonColors.primary,
                      onPressed: () {
                        SoundManager().playTick();
                        _showSaveDialog();
                      },
                    ),
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
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NeonColors.textSub.withOpacity(0.1)),
        ),
        child: Icon(icon, color: NeonColors.primary, size: 18),
      ),
    );
  }
}
