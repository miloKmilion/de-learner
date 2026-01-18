"""Tests for module_01 structure."""


def test_module_01_imports() -> None:
    """Test that module_01 can be imported."""
    import de_learner.module_01

    assert de_learner.module_01.__doc__ is not None
    assert "Module 01" in de_learner.module_01.__doc__
