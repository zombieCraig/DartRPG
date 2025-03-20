import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Game Name',
                  hintText: 'Enter a name for your game',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Game Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This game will use the Fe-Runners datasworn source.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_isCreating)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: ElevatedButton(
                    onPressed: _createGame,
                    child: const Text('Create Game'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGame() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
        
        // Create the game
        await gameProvider.createGame(
          _nameController.text,
          dataswornSource: 'assets/data/fe_runners.json',
        );
        
        // Explicitly save the game
        await gameProvider.saveGame();
        
        // Load the datasworn source
        await dataswornProvider.loadDatasworn('assets/data/fe_runners.json');
        
        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Game "${_nameController.text}" created successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          
          // Return to the game selection screen
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create game: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }
}
